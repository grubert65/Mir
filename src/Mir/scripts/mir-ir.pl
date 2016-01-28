#!/usr/bin/env perl
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#  Application Documentation
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

=head1 NAME

mir-ir.pl - Mir indexer process

=head1 VERSION

0.01

=head1 USAGE

    perl mir-ir.pl <JSON-encoded config file>

=head1 REQUIRED ARGUMENTS

The JSON-encoded configuration file should contain the following keys:

    idx_queue_params: Queue::Q class params to connect to the defined indexer queue
    idx_server      : Parameters for the indexer, should contain the following keys
        ir_params   : ElasticSearch server connect params passed to Mir::IR
        index       : The Elastic index to use
        mappings    : An hashref for the document and fields mappings

=head1 DESCRIPTION

=head1 AUTHOR

Marco Masetti (marco.masetti at softeco.it)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

#--------------------------------------------------------------------------------
use Moose;
use Getopt::Long            qw( GetOptions );
use JSON                    qw( decode_json );
use Queue::Q::ReliableFIFO::Redis ();
use Log::Log4perl           qw( :easy );
use Data::Dumper            qw( Dumper );
use Mir::IR;
use Mir::Config::Client ();
use Mir::Util::DocHandler ();
use Try::Tiny;
use Mir::Doc::File;
use Mir::Stat;

Log::Log4perl->easy_init( $INFO );
my $log = Log::Log4perl->get_logger( __PACKAGE__);

my $campaign;
my $config_driver = 'Mongo';
my $config_params = { section => 'system' };
my $config_params_json;

GetOptions ("campaign=s"        => \$campaign,
            "config_driver=s"   => \$config_driver,
            "config_params=s"   => \$config_params_json,
) or die("Error in command line arguments\n");
die "
Usage: $0 
 --campaign <campaign tag> \
 --config_driver  the Mir::Config::Client driver to use> (defaults to 'Mongo')
 --config_params  json-encoded string with the Mir::Config::Client driver specific params (defaults to section => 'system')

At least a campaign \n" unless $campaign ;

$config_params  = decode_json( $config_params_json ) if ( $config_params_json );

# loading suffix-driver lookup table...
my $drivers_lut;
{
    local $/;
    my $data=<DATA>;
    $drivers_lut = decode_json $data;
}

my $c = Mir::Config::Client->create( 
    driver => $config_driver,
    params => $config_params
) or die "No Mir::Config::Client object...\n";

$c->connect() or die "Error connecting to a Mir::Config data store\n";
my $params = $c->get_key({
        tag         => 'IR',
        campaign    => $campaign,
    },
    {
        idx_queue_params => 1,
        idx_server       => 1
    }
)->[0];

$log->debug("Going to connect to idx queue:");
$log->debug( Dumper $params->{idx_queue_params} );
$log->debug("Going to connect to Search Text Engine:");
$log->debug( Dumper $params->{idx_server}->{ir_params} );

$log->info("Opening queue:");
$log->info( Dumper $params->{idx_queue_params} );
my $q = Queue::Q::ReliableFIFO::Redis->new( %{ $params->{idx_queue_params} } );
my $e = Mir::IR->new( %{ $params->{idx_server}->{ir_params} } );
my $s = Mir::Stat->new(
    counter => $campaign.'_indexed',
    select  => 10,
);

# create index if not exists
# set mapping
unless ( $e->indices->exists( index => $params->{idx_server}->{index} ) ) {
    $e->indices->create( index => $params->{idx_server}->{index} );
    $e->indices->put_mapping(
        index   => $params->{idx_server}->{index},
        type    => $params->{idx_server}->{type},
        body    => $params->{idx_server}->{mappings}
    );
};

$log->info("Start consuming items...");
$q->consume( \&index_item, "drop" );

sub index_item {
    my $item = shift;

    $log->info( "Found NEW item -------------------------------------------");
    $log->info( $item->{id} );
    $log->debug( Dumper ( $item ) );

    unless ( $item ) {
        $log->error( "No item found!" );
        return 0; 
    }

    if ( not -f $item->{abspath} ) {
        $log->error( "File $item->{abspath} not exists or not readable" );
        return 0; 
    }

    my $item_obj = Mir::Doc::File->unpack( $item );
    unless ( $item_obj ) {
        $log->error("Error getting back a Mir::Doc::File obj");
        return;
    }
    my $item_to_index = $item_obj->to_index();

    $item_to_index->{pages} = [];
    my $dh;
    unless( $item_to_index->{suffix} && ( $dh = Mir::Util::DocHandler->create( driver => get_suffix ( $item_to_index->{suffix} ) ) ) ) {
        $log->warn("WARNING: no Mir::Util::DocHandler driver for document $item_to_index->{abspath}");
        return;
    }

    $log->info("Opening doc $item_to_index->{abspath}...");
    $dh->open_doc( $item_to_index->{abspath} ) or return;

    $item_to_index->{num_pages} = $dh->pages();
    $log->info( "Doc has $item_to_index->{num_pages} pages" );

    foreach( my $page=1;$page<=$item_to_index->{num_pages};$page++ ) {
        # get page text and confidence
        # add them to item profile
        push @{ $item_to_index->{pages} }, [ $dh->page_text( $page ) ];
    }

    try {
        # index item in the proper index...
        $log->info("Indexing document:");
        $log->info( Dumper $item_to_index );

        my $ret = $e->index( 
            index   => $params->{idx_server}->{index},
            type    => $params->{idx_server}->{type},
            body    => $item_to_index 
        );
        if ( $ret->{_id} ) {
            $log->info("Indexed document $item_to_index->{id}, IDX id: $ret->{_id}");
            $item_obj->{idx_id}     = $ret->{_id};
            $item_obj->{num_pages}  = $item_to_index->{num_pages};
            $item_obj->{status}     = 1; # 1 => INDEXED
            $item_obj->store();
            $s->incrBy();
        } else {
            $log->error("Error indexing document $item_to_index->{id}, no IDX ID");
        }
    } catch {
        $log->error("Error indexing document $item->{id}: $_");
    };
}

sub get_suffix {
    my $suffix = shift;
    ( $drivers_lut->{$suffix} ) ? return $drivers_lut->{$suffix} : $suffix;
}

__DATA__
{
    "pdf":"pdf2",
    "html": "html",
    "doc":  "doc",
    "docx": "doc",
    "rtf":  "rtf",
    "java": "txt",
    "js":   "txt",
    "pm":   "txt"
}

package Mir::IR;
#============================================================= -*-perl-*-

=head1 NAME

Mir::IR - frontend for the Elastic Search indexer.

=head1 VERSION

0.12

=cut

#HISTORY
# 0.05 | 26.02.2016 | Decoding abspath from utf8 octets to characters....
# 0.06 | 17.03.2016 | Mean confidence added to store after indexing doc...
# 0.07 | 18.03.2016 | utf8 decoding of apspath commented out...
# 0.08 | 22.03.2016 | got rid of issue on Mir::Doc::File->store sub...
# 0.09 | 01.04.2016 | Now considering path instead of abspath...
# 0.10 | 20.04.2016 | Logs added...
# 0.11 | 22.04.2016 | Lowercase suffix...
# 0.12 | 04.05.2016 | Properly handling of not valid suffix
# 0.13 | 04.07.2016 | Does not bother is idx queue doesn't exists
# 0.14 | 22.09.2016 | Now handlogic can be extended via plugins
our $VERSION = '0.14';

=head1 SYNOPSIS

    use Mir::IR ();

    my $ir = Mir::IR->new(
        campaign      => $campaign,
        config_driver => $config_driver,     # Mongo by default...
        config_params => $config_params_json
    );

    # config objects and create Elastic index (if not exists)...
    # (see Mir::Config IR section in system collection)
    $ir->config();

    # consumes all items in queue
    # for each document profile, get document text 
    # and index it
    $ir->process_items_in_queue();

    #...or goes polling for new documents in store...
    $ir->process_new_items( $polling_period );

=head1 DESCRIPTION

This class extends the base Search::Elasticsearch to provides utility methods.

=head1 AUTHOR

Marco Masetti (marco.masetti @ softeco.it )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SUBROUTINES/METHODS

=cut

#========================================================================
use v5.10;
use Moose;
with 'Mir::R::PluginHandler';

use Search::Elasticsearch;
use namespace::clean;
use Log::Log4perl;
use Queue::Q::ReliableFIFO::Redis ();
use Log::Log4perl           qw( :easy );
use Data::Dumper            qw( Dumper );
use TryCatch;
use JSON;
use Mir::Config::Client ();
use Mir::Util::DocHandler ();
use Mir::Doc;
use Mir::Stat ();
use Mir::Store ();
use Encode;


use vars qw( 
    $log 
    $stat
    $drivers_lut
    $confidence_threashold
    $index
    $type
    @mapping_keys
    $e
);

$log = Log::Log4perl->get_logger( __PACKAGE__ );
{
    local $/;
    my $data=<DATA>;
    $drivers_lut = decode_json $data;
}

has 'campaign'      => ( is => 'rw', isa => 'Str', required => 1 );

# params to get a Mir::Config obj...
has 'config_driver' => ( is => 'rw', isa => 'Str', default => sub { return 'Mongo' } );
has 'config_params' => ( is => 'rw', isa => 'HashRef' );
has 'config_params_json' => ( is => 'rw', isa => 'Str' );
has 'queue'         => ( is => 'rw', isa => 'Queue::Q::ReliableFIFO::Redis' );

has 'params'     => ( is => 'rw', isa => 'HashRef' );
has 'sleeping_time' => ( is => 'rw', isa => 'Int', default => sub { return 3600 } );
has 'e' => ( 
    is => 'ro', 
    isa => 'Search::Elasticsearch::Client::2_0::Direct', 
    lazy => 1, 
    default => sub { return $e } 
);

#=============================================================

=head2 config

=head3 INPUT

=head3 OUTPUT

1 or die in case of errors.

=head3 DESCRIPTION

Configure the object.
Configuration is handled by Mir::Config.
The method uses a Mir::Config::Client object to get the 
configuration. Usually, by default, this means accessing
the system collection of the MIR Mongo database...

=cut

#=============================================================
sub config {
    my $self = shift;

    $self->config_params( decode_json( $self->config_params_json ) ) 
        if ( $self->config_params_json );

    my $c = Mir::Config::Client->create( 
        driver => $self->config_driver,
        params => $self->config_params
    ) or die "No Mir::Config::Client object...\n";
    
    $c->connect() or die "Error connecting to a Mir::Config data store\n";
    $self->params( $c->get_key({
            campaign    => $self->campaign,
        }, { params => 1 }
    )->[0]->{params});

    # Register any plugins configured to be executed 
    # at giveln locations
#      $DB::single=1;
     if ( exists $self->params->{idx_server}->{plugins} ) {
         $self->register_plugins( $self->params->{idx_server}->{plugins} );
     }

    $log->debug("Going to connect to Search Text Engine:");
    $log->debug( Dumper $self->params->{idx_server}->{ir_params} );

    $index = $self->params->{idx_server}->{index};
    $type  = $self->params->{idx_server}->{type};
    $log->info("Going to index docs of type $type into index $index");

    if ( exists $self->params->{idx_queue_params} ) {
        $log->debug("Going to connect to idx queue:");
        $log->debug( Dumper $self->params->{idx_queue_params} );
        $self->queue( Queue::Q::ReliableFIFO::Redis->new( %{ $self->params->{idx_queue_params} } ) )
            or die "Error getting a Queue::Q::ReliableFIFO::Redis object\n";
    } else {
        $log->info("No queue defined for this campaign...can only work polling docs...");
    }

    $log->debug("Getting a Search::Elasticsearch object with params:");
    $log->debug( Dumper $self->params->{idx_server}->{ir_params} );
    $e = Search::Elasticsearch->new( %{ $self->params->{idx_server}->{ir_params} } );

    $log->debug( "Getting a Mir::Stat object for counter $self->{campaign}" );
    # stat section should contains the server and select keys...
    if ( exists ( $self->params->{idx_server}->{stat} ) ) {
        $stat = Mir::Stat->new(
            counter => $self->{campaign}.'_indexed',
            %{ $self->params->{idx_server}->{stat} }
        );
    }

    $drivers_lut = $self->params->{idx_server}->{doc_handlers_lut} if ( $self->params->{idx_server}->{doc_handlers_lut} );
    # if no threashold defined we take everything...
    $confidence_threashold = $self->params->{idx_server}->{confidence_threashold} || 0; 

    my $mappings = $c->get_key(
        { tag => 'elastic' }, 
        { mappings => 1 }
    )->[0]->{'mappings'};

    $log->warn("WARNING: No mappings section found in config")
        unless $mappings;

    if ( $mappings && exists $mappings->{$type}->{properties} ) {
        @mapping_keys = keys %{ $mappings->{$type}->{properties} };
    }

    #now we check if the index exists, otherwise we create it with the right
    #mapping...
    unless ( $e->indices->exists( index => $index ) ) {
        try {
            if ( exists $mappings->{$type} ) {
                $e->indices->create(
                    index   => $index,
                    body    => { mappings => { $type => $mappings->{$type} } }
                ) or die "Error creating index $index for document $type\n";
            } else {
                $e->indices->create( index => $index ) or die "Error creating index $index\n";
            }
        } catch ( Search::Elasticsearch::Error $err ) {
            die "Error creating index $index : type $err->{type}\nMsg: $err->{text}\n";
        }
    }

    return 1;
}

#=============================================================

=head2 process_items_in_queue

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

=cut

#=============================================================
sub process_items_in_queue {
    my $self = shift;

    $log->info("Start consuming items...");
    if ( $self->queue ) {
        $self->queue->consume( \&_index_item, "drop" );
    } else {
        $log->error("Cannot consume items from queue, queue doesn't exists!");
    }
}

#=============================================================

=head2 _index_item

=head3 INPUT

A Mir::Doc::File object or a hash representing a doc profile

=head3 OUTPUT

The result of the index or undef in case of errors.

=head3 DESCRIPTION

Queue items consuming callback.
Tries to extract the text from the object and index it in the 
index, for the type and with the mapping configured.

=cut

#=============================================================
sub _index_item {
    my ( $self, $item ) = (ref $_[0] eq 'HASH') ? (undef, $_[0] ) : @_;

    unless ( $item ) {
        $log->error( "No item found!" );
        return 0; 
    }

    $log->info( "ITEM -------------------------------------------");
    $log->info( $item->{id} );
    $log->debug( Dumper ( $item ) );

    if ( not -f "$item->{path}" ) {
        $log->error( "File $item->{path} not exists or not readable" );
        return 0; 
    }

    my $store;
    if ( exists ( $item->{storage_io_params} ) ) {
        $store = Mir::Store->create(
            driver => $item->{storage_io_params}->{io}->[0],
            params => $item->{storage_io_params}->{io}->[1]
        );
        $store->connect();
    }

    my $ret;
    my %item_to_index;
    my $new_status = Mir::Doc::INDEXED; # think positive...
    @item_to_index{@mapping_keys} = @$item{@mapping_keys};

    if ( get_text( \%item_to_index ) == Mir::Doc::INVALID_SUFFIX ) {
        $log->error("Suffix $item->{suffix} NOT VALID");
        $new_status = Mir::Doc::INVALID_SUFFIX;
    }

    # if no text is found we index as well but mark indexed document as NO_TEXT
    # actually any invalid suffix gets this...
#    unless ( scalar @{$item_to_index{text}} ) {
#        $log->error("Doc. $item->{path}");
#        $log->error("No text found, indexing metadata...");
#        $new_status = Mir::Doc::NO_TEXT;
#    }

    if ( scalar @{$item_to_index{text}} && 
        ( $item_to_index{mean_confidence} < $confidence_threashold ) ) {
        $log->error("Doc. $item->{path}");
        $log->error("Mean confidence under threashold, indexing metadata...");
        $new_status = Mir::Doc::CONF_TOO_LOW;
    }

     try {

        # run all plugins registered for the after_text_extraction hook
        # the input params will be added to the list of parameters
        # already configured for each plugin...
        # all these plugins should change the item that is going to
        # be indexed...
        my $out = {};
        $self->call_registered_plugins( {
            hook            => 'after_text_extraction',
            output_params   => \%item_to_index,
            input_params    => {
                doc => \%item_to_index
            }
        } ) if ( defined $self );  #we can call class registered plugins only if we are
                                   # an object...

        # index item in the proper index...
        $log->info("Indexing document: $item_to_index{id}");
        $log->debug( Dumper \%item_to_index );

        $ret = $e->index( 
            index   => $index,
            id      => $item->{idx_id}, # in case this item has been already indexed...
            type    => $type,
            body    => \%item_to_index 
        );

        if ( $ret->{_id} ) {
            $log->info("Indexed document $item_to_index{id}, IDX id: $ret->{_id}");
            $stat->incrBy() if ( $stat );

            if ( $store ) {
                $store->update( { '_id' => $item->{_id} }, {'$set' => {
                        idx_id          => $ret->{_id},
                        status          => $new_status,
                        mean_confidence => $item_to_index{mean_confidence},
                        num_pages       => $item_to_index{num_pages} 
                        }
                    }
                );
            } else {
                $log->error("NO store defined for this doc");
            }
        } else {
            $log->error("Error indexing document $item_to_index{id}, no IDX ID");
            $store->update( { '_id' => $item->{_id} }, {'$set' => {
                    status          => Mir::Doc::IDX_FAILED,
                    }
                }
            ) if ( $store );
        }
     } catch ( $err ) {
         $log->error("Error indexing document $item->{id}: $err");
        $store->update( { '_id' => $item->{_id} }, {'$set' => {
                status          => Mir::Doc::IDX_FAILED,
                }
            }
        ) if ( $store );
    };
    return ( $ret );
}

#=============================================================

=head2 get_text

=head3 INPUT

    $doc : the document metadata hashref

=head3 OUTPUT

1/undef in case of errors

=head3 DESCRIPTION

Tries its best to get the page texts out of the document.
Computes the overall text extraction confidence.
Page text is collected in the arrayref $doc->{text}.

=cut

#=============================================================
sub get_text {
    my $doc = $_[0];

    $doc->{text} = [];
    $doc->{mean_confidence} = 0;

    try {
        my $dh;
        my $mean_confidence=0;
        if ( $doc->{suffix} && ( $dh = Mir::Util::DocHandler->create( driver => get_driver ( lc $doc->{suffix} ) ) ) ) {
            $log->info("Opening doc $doc->{path}...");
            $dh->open_doc( "$doc->{path}" ) or return;
        
            $doc->{num_pages} = $dh->pages();
            $log->info( "Doc has $doc->{num_pages} pages" );
        
            foreach( my $page=1;$page<=$doc->{num_pages};$page++ ) {
                # get page text and confidence
                # add them to item profile
                my ( $text, $confidence ) = $dh->page_text( $page, $ENV{MIR_TEMP}||'/tmp' );
                $log->debug("Confidence: $confidence");
                $log->debug("Text      :\n\n$text");
                if ( $text && $confidence ) {
                    push @{ $doc->{text} }, $text;
                    $mean_confidence += $confidence;
                } else {
                    $log->warn("Text or confidence undefined, skipping text");
                }
            }
            $dh->delete_temp_files();
            $doc->{mean_confidence} = $mean_confidence/$doc->{num_pages};
        } else {
            $log->warn("WARNING: no Mir::Util::DocHandler driver for document $doc->{path}");
            return Mir::Doc::INVALID_SUFFIX;
        }
    } catch {
        $log->error("Error getting text for document:");
        $log->error( $doc->{path} );
        $log->error($@);
        return Mir::Doc::INVALID_SUFFIX;
    }

    return 1;
}

#=============================================================

=head2 get_driver

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

Returns the Mir::Util::DocHandler driver based on the document
suffix.

=cut

#=============================================================
sub get_driver {
    my $suffix = shift;
    ( $drivers_lut->{$suffix} ) ? return $drivers_lut->{$suffix} : $suffix;
}

#=============================================================

=head2 exists

=head3 INPUT

    $id: the document id

=head3 OUTPUT

1 if doc exists

=head3 DESCRIPTION

Check if document with the passed id has been already indexed.
Returns the total number of hits found.

=cut

#=============================================================
sub exists {
    my ( $self, $id, $index ) = @_;

    return undef unless $id;
    my $filter = { 
        match => { id => $id }
    };
    my $res;
    try {
        $res = $e->search(
            index => $index,
            body  => { query => $filter }
        );
    } catch {
        $log->error("Error checking for doc $id: $@");
        return undef;
    }
    return $res->{hits}->{total};
}

#=============================================================

=head2 process_new_items

=head3 INPUT

    $polling_period: number of seconds to sleep if no documents 
                     to index are found.

=head3 OUTPUT

=head3 DESCRIPTION

Workflow:
    - get a new document from Store, otherwise sleep for a while
    - index it

A store reference is defined for each fetcher configured for
the campaign.
We define a static index to loop for each store data source.

=cut

#=============================================================
sub process_new_items {
    my ( $self, $polling_period ) = @_;

    $log->debug("Start polling for new items");

    my @store_params;
    my @stores;
    state $index = 0;
    foreach my $fetcher ( @{ $self->params->{fetchers} } ) {
        push @store_params, $fetcher->{params}->{storage_io_params}->{io};
    }

    foreach my $store_params ( @store_params ) {
        try {
            my $store = Mir::Store->create(
                driver => $store_params->[0],
                params => $store_params->[1]
            );
            $store->connect();
            push @stores, $store;
        } catch {
            $log->error("Error getting a Mir::Store obj with params");
            $log->error(Dumper($store_params));
        }
    }

    # ...and finally the loop...
    while (1) {
        $index = 0 if ( $index == scalar @stores );
        my $doc = $stores[$index]->get_new_doc(mark_as_indexing => 1);
        unless ( $doc ) {
            $log->info ("No new docs to index, going to sleep...");
            return 1 if ( $ENV{TEST_FILE} || $ENV{HARNESS_ACTIVE} );
            sleep ( $polling_period || $self->sleeping_time );
            $index++;
            next;
        }
        $self->_index_item( $doc );
        $index++;
    }
}

1;

__DATA__
{
    "pdf":  "pdf3",
    "html": "html",
    "doc":  "doc",
    "docx": "docx",
    "rtf":  "rtf",
    "java": "txt",
    "js":   "txt",
    "pm":   "txt",
    "json": "txt"
}

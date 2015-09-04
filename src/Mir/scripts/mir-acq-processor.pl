#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-acq-processor.pl
#
#        USAGE: ./mir-acq-processor.pl  <campaign>
#
#  DESCRIPTION: gets the next fetcher for the campaign and executes it in an endless loop. 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 08/20/2015 05:19:35 PM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use utf8;
use Queue::Q::ReliableFIFO::Redis   ();
#use Parallel::ForkManager;
use Log::Log4perl                   qw( :easy );
use YAML                            qw( Load );
use Getopt::Long                    qw( GetOptions );

Log::Log4perl->easy_init( $DEBUG );
my $log = Log::Log4perl->get_logger();
my $config;

{
    local $/;
    my $data = <DATA>;
    $config = Load( $data );
}

# by default we consume queue items in chunks of 3 items
# at a time and don't pause between sessions
my ( $campaign, $chunk, $pause, $server, $port ) = ( undef, 3, 10, 'localhost', 6379 );
GetOptions (
    "campaign=s"    => \$campaign,
    "chunk=i"       => \$chunk,
    "pause=i"       => \$pause,
    "server=s"      => \$server,
    "port=i"        => \$port
) or die "Usage: $0 --campaign <campaign tag> [ --chunk <number of items in chunk> ] [ --pause <number of seconds to sleep between sessions> ] [--server <queue server IP address>] [--port <queue server port number>]\n";

die ("At least the campaign has to be passed via the --campaign input param\n") unless $campaign;

$log->debug("Executing (max) $chunk fetchers for campaign: $campaign...");

my $q = Queue::Q::ReliableFIFO::Redis->new(
            server     => $server,
            port       => $port,
            queue_name => $campaign,
) or die "Error creating a queue for campaign $campaign\n";

$q->consume( \&run_fetchers, "drop", { 
        Chunk       => $chunk, 
        Pause       => $pause,
        ProcessAll  => 1, #process all items found in one chunk
} );

sub run_fetchers {
    my @items = @_;

    $log->debug("Got items:");
    $log->debug( Dumper ( @items ) );
    print ( Dumper( @items ));

#    my $pm = Parallel::ForkManager->new($chunk);

    foreach my $item ( @items ) {
        next unless $item->{ns};

        $log->debug("Got item:");
        $log->debug( Dumper ( $item ) );

#        my $pid = $pm->start and next LOOP;
        my $pid = fork() and next;

        $log->debug("Process $pid forked!");

        my $class = $config->{FETCHER_NS_PREFIX}.'::'.$item->{ns};

        eval {
            $log->debug("Trying with class $class in child $pid ...");
            require $class;
            my $o = $class->new( $item->{params} );
            $o->fetch();
        };
        if ( $@ ) {
            $log->error( "Error getting an obj for fetcher $class: $@");
        }

        $log->debug("Closing thread $pid");
        exit();
#        $pm->finish;
    }

    $log->debug("Wait for all children to die...");
#    $pm->wait_all_children;
    while ( wait() != -1 ) {};
    $log->debug("All children died!!");
}








while ( 1 ) {
    my $fetcher = $q->claim_item || { ns => 'Sleep' };

    my $class = $config->{FETCHER_NS_PREFIX}.'::'.$fetcher->{ns};

    eval {
        require $class;
        my $o = $class->new();
        $o->fetch();
        $q->mark_item_as_done($fetcher);
    };
    if ( $@ ) {
        $log->error( "Error getting an obj for fetcher $class");
        die "Error getting an obj for fetcher $class\n";
    }
}

__DATA__
FETCHER_NS_PREFIX: 'Mir::ACQ::Fetcher'

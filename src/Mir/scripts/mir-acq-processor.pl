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
#       AUTHOR: Marco Masetti (marco.masetti at softeco.it)
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 08/20/2015 05:19:35 PM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use feature "state";
use utf8;
use Queue::Q::ReliableFIFO::Redis   ();
use Parallel::ForkManager;
use Log::Log4perl                   qw( :easy );
use YAML                            qw( Load );
use Getopt::Long                    qw( GetOptions );
use Data::Dumper                    qw( Dumper );

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
) or die <<EOT;

Usage: $0 --campaign <campaign tag> 
          [--chunk <number of items in chunk> ] 
          [--pause <number of seconds to sleep between sessions> ] 
          [--server <queue server IP address>] 
          [--port <queue server port number>]

EOT

die ("At least the campaign has to be passed via the --campaign input param\n") unless $campaign;

my $pm = Parallel::ForkManager->new($chunk);

$log->debug("Executing (max) $chunk fetchers for campaign: $campaign...");

my $q = Queue::Q::ReliableFIFO::Redis->new(
            server     => $server,
            port       => $port,
            queue_name => $campaign,
) or die "Error creating a queue for campaign $campaign\n";

$q->consume( \&run_fetchers, "drop", { 
        Chunk       => $chunk, 
        Pause       => ( $chunk > 1 ) ? $pause : undef,
        ProcessAll  => ( $chunk > 1 ) ? 1 : undef, #process all items found in one chunk
} );

sub run_fetchers {
    my @items = @_;

    state $called_times = 1;
    state $thread = 0;
    $log->debug( "CYCLE NUMBER: $called_times ------------\n" );

    my $class;
    foreach my $item ( @items ) {
        if ( defined $item->{ns} ) {
            $class= "Mir::Acq::Fetcher".'::'.$item->{ns};
            eval "require $class";
            if ( $@ ) {
                $log->error ("Error, class $class not found\n");
                next;
            }
        }
    }

    FETCHER_LOOP:
    foreach my $item ( @items ) {
        # TODO 
        # this should be removed from here...
    	$ENV{WUNDERGROUND_API} = $config->{WUNDERGROUND_API};
        $thread++;
        my $pid = $pm->start and next FETCHER_LOOP;
        $log->debug ("Thread: ".$thread."\n");
        $log->debug ("Received:\n");
        $log->debug (Dumper $item );
        $class= "Mir::Acq::Fetcher".'::'.$item->{ns}
            if ( defined $item->{ns} );
        if ( defined $class ) {
            $log->debug ("Going to create a $class fetcher...\n");
            # the proc_queue_params are needed in case
            # the fetcher needs to enqueue itself back
            my $o = $class->new( 
                $item,
                proc_queue_params => {
                    server     => $server,
                    port       => $port,
                    queue_name => $campaign,
                }
            );
            $o->fetch();
        } else {
            $log->error ("ERROR, no class defined !!\n");
        }
        $pm->finish;
    }
    $pm->wait_all_children;
    print "All children ended\n";
    $called_times++;
}

__DATA__
FETCHER_NS_PREFIX: 'Mir::ACQ::Fetcher'
WUNDERGROUND_API: 'f9a17cd41b53bb13'

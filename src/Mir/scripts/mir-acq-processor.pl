#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-acq-processor.pl
#
#        USAGE: ./mir-acq-processor.pl  --campaign <campaign>
#
#  DESCRIPTION: Gets the next chunk of fetchers for the campaign and executes them 
#               in an endless loop. 
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
use TryCatch;
use Mir::Stat ();

my $config;

{
    local $/;
    my $data = <DATA>;
    $config = Load( $data );
}

# by default we consume queue items in chunks of 3 items
# at a time and don't pause between sessions
my ( $campaign, $chunk, $pause, $server, $port ) = ( undef, 3, 10, 'localhost', 6379 );
my $log_config_params;

GetOptions (
    "campaign=s"    => \$campaign,
    "chunk=i"       => \$chunk,
    "pause=i"       => \$pause,
    "server=s"      => \$server,
    "log_config_params=s"   => \$log_config_params,
    "port=i"        => \$port
) or die <<EOT;

Usage: $0 --campaign <campaign tag> 
          [--chunk <number of items in chunk>                     (defaults to 3)] 
          [--pause <number of seconds to sleep between sessions> (defaults to 10)] 
          [--server <queue server IP address>             (defaults to localhost)] 
          [--port <queue server port number>                   (defaults to 6379)]
          [--log_config_params <a Log::Log4perl config file> (defaults to stdout)]

EOT

die ("At least the campaign has to be passed via the --campaign input param\n") unless $campaign;

( $log_config_params ) ? Log::Log4perl->init( $log_config_params ) : Log::Log4perl->easy_init( $DEBUG );
my $log = Log::Log4perl->get_logger();

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

    FETCHER_LOOP:
    foreach my $item ( @items ) {
        my $class;
        # TODO 
        # this should be removed from here...
    	$ENV{WUNDERGROUND_API} = $config->{WUNDERGROUND_API};
        $thread++;
        my $pid = $pm->start and next FETCHER_LOOP;
        $log->debug ("Thread: ".$thread."\n");
        $log->debug ("Received:\n");
        $log->debug (Dumper $item );
        try {
            #-----------------------------------------------------
            # we actually added the DriverRole to the Mir::Acq::Fetcher class
            # this means that this old code can be commented out...
#             $class= "Mir::Acq::Fetcher".'::'.$item->{ns}
#                 if ( defined $item->{ns} );
#             eval "require $class";
#             my $o = $class->new( %{$item->{params}} );
             $log->debug ("Going to create a $class fetcher...\n");
             $log->debug ("With params:");
             $log->debug ( Dumper ( $item->{params} ) );
            #-----------------------------------------------------
            # NEW CODE
            #-----------------------------------------------------
            my $o = Mir::Acq::Fetcher->create(
                driver => $item->{ns},
                params => $item # NOTE : should be $item->{params}
                                # this is due to the fact that some processors 
                                # expects a "params" hashref as input
            );
            $o->fetch();
            my $stat = Mir::Stat->new(
                counter => $campaign.'_fetched',
                select  => 10,
            );
            $stat->incrBy( scalar @{ $o->{docs} } );
        } catch( $err ) {
            $log->error ( $err );
        }
        $pm->finish;
    }
    $log->debug( "Waiting for all children to die...");
    $pm->wait_all_children;
    $log->debug( "All children ended" );
    $called_times++;
}

__DATA__
FETCHER_NS_PREFIX: 'Mir::ACQ::Fetcher'
WUNDERGROUND_API: 'f9a17cd41b53bb13'

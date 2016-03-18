#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-acq-weatheralerts-processor.pl
#
#        USAGE: ./mir-acq-weatheralerts-processor.pl  
#
#  DESCRIPTION: gets the next weather alert and sends it to alerts web service, 
#               executing it in an endless loop.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 03/16/2016 09:36:32 AM
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
use JSON                            ;
use Getopt::Long                    qw( GetOptions );
use LWP::UserAgent                  ;
use Data::Dumper                    qw( Dumper );

Log::Log4perl->easy_init( $DEBUG );
my $log = Log::Log4perl->get_logger();
my $config;

# by default we consume queue items in chunks of 1 item
# at a time and don't pause between sessions
my ( $fetcher, $chunk, $pause, $server, $port ) = ( undef, 1, 10, 'localhost', 6379 );

GetOptions (
    "fetcher=s"    => \$fetcher,
    "chunk=i"       => \$chunk,
    "pause=i"       => \$pause,
    "server=s"      => \$server,
    "port=i"        => \$port
) or die <<EOT;

Usage: $0 --fetcher <fetcher tag> 
          [--chunk <number of items in chunk> ] 
          [--pause <number of seconds to sleep between sessions> ] 
          [--server <queue server IP address>] 
          [--port <queue server port number>]

EOT

die ("At least the fetcher has to be passed via the --fetcher input param\n") unless $fetcher;

my $pm = Parallel::ForkManager->new($chunk);

$log->debug("Executing (max) $chunk fetchers for fetcher: $fetcher...");

my $q = Queue::Q::ReliableFIFO::Redis->new(
            server     => $server,
            port       => $port,
            queue_name => $fetcher,
) or die "Error creating a queue for fetcher $fetcher\n";

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
        $thread++;
        my $pid = $pm->start and next FETCHER_LOOP;
        $log->debug ("Thread: ".$thread."\n");
        $log->debug ("Received:\n");
        $log->debug (Dumper $item );

        # Send data to services here
        my $ua = LWP::UserAgent->new;
        my $auth_service = 'http://www.grupposigla.it/starteco_api/das/v1/login';
        my $alert_service = 'http://www.grupposigla.it/starteco_api/das/v1/weather_alerts';

        # set custom HTTP request header fields for login
        my $req = HTTP::Request->new(POST => $auth_service);
        $req->header('content-type' => 'application/json');
         
        # add POST data to HTTP request body
        my $credentials = {
            username    => "softeco",
            password    => "starteco2016"
        };
        $req->content(to_json($credentials));
         
        my $resp = $ua->request($req);
        if ($resp->is_success) {
            my $content = $resp->decoded_content;
            print "Received successful reply: $content\n";
            my $message = decode_json($content);
            print "Received token ".$message->{token}." expiring on ".$message->{expiry_date}."\n";

$DB::single=1;
            # Create request to weather alert service
            $req = HTTP::Request->new(POST => $alert_service);
            # set custom HTTP request header fields to send alert content
            $req->header('content-type' => 'application/json');
            $req->header('token' => $message->{token});
            my $current_observation = {
                current_observation => $item
            };
            $req->content(to_json($current_observation));
            $resp = $ua->request($req);
            if ($resp->is_success) {
                $content = $resp->decoded_content;
                print "Received successful reply: $content\n";
            } else {
                print "HTTP POST error code: ", $resp->code, "\n";
                print "HTTP POST error message: ", $resp->message, "\n";
            }
        }
        else {
            print "HTTP POST error code: ", $resp->code, "\n";
            print "HTTP POST error message: ", $resp->message, "\n";
        }

        $pm->finish;
    }
    $pm->wait_all_children;
    print "All children ended\n";
    $called_times++;
}

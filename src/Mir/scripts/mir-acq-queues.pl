use strict;
use warnings;
use Getopt::Long qw( GetOptions);
use Queue::Q::ReliableFIFO::Redis;
use Data::Dumper qw( Dumper );

my $campaign;
my $server  = 'localhost';
my $port    = 6379;

GetOptions(
    "campaign=s"    => \$campaign,
    "server=s"      => \$server,
    "port=i"        => \$port
) or die "Usage: $0 --campaign <campaign_tag> [ --server <queue server IP> ] [ --port <queue port number>]\n";

die "Usage: $0 --campaign <campaign_tag> [ --server <queue server IP> ] [ --port <queue port number>]\n"
    unless ( defined $campaign );

print "Going to connect to queue @ $server, port $port for campaign $campaign\n";

my $queue = Queue::Q::ReliableFIFO::Redis->new(
    server     => $server,
    port       => $port,
    queue_name => $campaign,
) or die "Error creating a queue for campaign $campaign\n";

$queue->consume( \&handle_item, "drop", { Chunk => 1 }  );

sub handle_item {
    my $item = shift;
    print "Received: ", Dumper( $item ), "\n";
}

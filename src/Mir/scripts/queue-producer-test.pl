use strict;
use warnings;
use Getopt::Long qw( GetOptions);
use Queue::Q::ReliableFIFO::Redis;
use Data::Dumper qw( Dumper );
use JSON qw(encode_json decode_json);

my $campaign;
my $server  = 'localhost';
my $port    = 6379;
my $fetcher;
my $params;

GetOptions(
    "campaign=s"    => \$campaign,
    "server=s"      => \$server,
    "port=i"        => \$port,
    "fetcher=s"     => \$fetcher,
    "params=s"      => \$params,
) or die "Usage: $0 --campaign <campaign_tag> --fetcher <fetcher namespace> --params <fetcher JSON-encoded params> [ --server <queue server IP> ] [ --port <queue port number>]\n";

die "At least the campaign, the fetcher and fetcher params needs to be passed\n"
    unless ( defined $campaign && $fetcher );

my $q = Queue::Q::ReliableFIFO::Redis->new(
    server     => $server,
    port       => $port,
    queue_name => $campaign,
) or die "Error creating a queue for campaign $campaign\n";

my $item = {
    campaign=> $campaign,
    ns      => $fetcher,
    params  => decode_json $params,
};

print "Going to enqueue item:\n";
print encode_json( $item ),"\n";

$q->enqueue_item( $item );


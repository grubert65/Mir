#
# questo script prova come leggere dalla coda a chunks di un numero di elementi massimo configurato via il parametro "Chunk" e aspettando un numero di secondi configurato dal parametro "Pause" tra un ciclo ed il successivo.
# La callback viene inoltre chiamata una sola volta...
use strict;
use warnings;
use Getopt::Long qw( GetOptions);
use Queue::Q::ReliableFIFO::Redis;
use Data::Dumper qw( Dumper );
use JSON qw(encode_json decode_json);
use feature "state";

my $campaign;
my $server  = 'localhost';
my $port    = 6379;
my $fetcher;
my $params;

GetOptions(
    "campaign=s"    => \$campaign,
    "server=s"      => \$server,
    "port=i"        => \$port,
) or die "Usage: $0 --campaign <campaign_tag> [ --server <queue server IP> ] [ --port <queue port number>]\n";

die "At least the campaign needs to be passed\n"
    unless ( defined $campaign );

my $q = Queue::Q::ReliableFIFO::Redis->new(
    server     => $server,
    port       => $port,
    queue_name => $campaign,
) or die "Error creating a queue for campaign $campaign\n";

$q->consume( \&handle_items, "drop", { 
        Chunk       => 3, 
        Pause       => 20,
        ProcessAll  => 1,
    } );

sub handle_item {
    my $item = shift;
    state $called_times = 1;

    print "CYCLE NUMBER: $called_times ------------\n";
    print "Received:\n";
    print Dumper $item;
    print "\n";
    $called_times++;

}

sub handle_items {
    my @items = @_;
    state $called_times = 1;

    print "CYCLE NUMBER: $called_times ------------\n";

    foreach my $item ( @items ) {
        print "Received:\n";
        print Dumper $item;
        print "\n";
    }

    $called_times++;
}

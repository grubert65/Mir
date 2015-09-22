use strict;
use warnings;
use Getopt::Long qw( GetOptions);
use Queue::Q::ReliableFIFO::Redis;
use Data::Dumper qw( Dumper );
use JSON qw(encode_json decode_json);
use Parallel::ForkManager;
use feature "state";
use Log::Log4perl qw( :easy );

Log::Log4perl->easy_init( $DEBUG );

my $campaign;
my $chunk   = 3;
my $pause   = 2;
my $server  = 'localhost';
my $port    = 6379;
my $fetcher;
my $params;

GetOptions(
    "campaign=s"    => \$campaign,
    "server=s"      => \$server,
    "port=i"        => \$port,
    "chunk=s"       => \$chunk,
    "pause=s"       => \$pause,
) or die <<EOT;

    Usage: $0 --campaign <campaign_tag> 
            [ --server <queue server IP> ] (default localhost)
            [ --port <queue port number> ] (defautl 6379)
            [ --chunk <number of chunks> ] (default 3)
            [ --pause <seconds of pause> ] (default 2)

EOT

die "At least the campaign needs to be passed\n"
    unless ( defined $campaign );

my $pm = Parallel::ForkManager->new($chunk);

my $q = Queue::Q::ReliableFIFO::Redis->new(
    server     => $server,
    port       => $port,
    queue_name => $campaign,
) or die "Error creating a queue for campaign $campaign\n";

print "Consuming items from queue $campaign with chunk of $chunk items....\n";

$q->consume( \&handle_items, "drop", { 
        Chunk       => $chunk, 
        Pause       => ( $chunk > 1 ) ? $pause : undef,
        ProcessAll  => ( $chunk > 1 ) ? 1 : undef,
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
    state $thread = 0;
    print "CYCLE NUMBER: $called_times ------------\n";

    my $class;
    foreach my $item ( @items ) {
        if ( defined $item->{ns} ) {
            $class= "Mir::Acq::Fetcher".'::'.$item->{ns};
            eval "require $class";
            if ( $@ ) {
                print "Error, class $class not found\n";
                next;
            }
        }
    }

    FETCHER_LOOP:
    foreach my $item ( @items ) {
        $thread++;
        my $pid = $pm->start and next FETCHER_LOOP;
        print "Thread: ".$thread."\n";
        print "Received:\n";
        print Dumper $item;
        print "\n";
        $class= "Mir::Acq::Fetcher".'::'.$item->{ns}
            if ( defined $item->{ns} );
        if ( defined $class ) {
            print "Going to create a $class fetcher...\n";
            $DB::single=1;
            my $o = $class->new( $item );
            $o->fetch();
        } else {
            print "ERROR, no class defined !!\n";
        }
        $pm->finish;
    }
    $pm->wait_all_children;
    print "All children ended\n";
    $called_times++;
}

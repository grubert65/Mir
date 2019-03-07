use strict;
use warnings;
use Benchmark qw( timethese );

use Mir::Queue ();
use Queue::Q::ReliableFIFO::Redis;

our $scalar_item = "foo";
our $hash_item = {
    key1    => 'value1',
    key2    => { key3 => 'value3' }
};

sub qq_str_producer {

    my $q = Queue::Q::ReliableFIFO::Redis->new(
        server     => 'localhost',
        port       => 6379,
        queue_name => 'qq-test'
    ) or die "Error creating a queue Queue::Q\n";

    $q->enqueue_item( $scalar_item );
}

sub qq_hash_producer {

    my $q = Queue::Q::ReliableFIFO::Redis->new(
        server     => 'localhost',
        port       => 6379,
        queue_name => 'qq-test'
    ) or die "Error creating a queue Queue::Q\n";

    $q->enqueue_item( $hash_item );
}

sub mq_str_producer {

    my $q = Mir::Queue->create(
            driver  => 'Redis',
            params  => {
                connect => { server => '127.0.0.1:6379' }, 
                db      => 1,
                key     => 'test'
            }
    ) or die "Error creating a queue Mir::Queue\n";

    $q->push( $scalar_item );
}

sub mq_hash_producer {

    my $q = Mir::Queue->create(
            driver  => 'Redis',
            params  => {
                connect => { server => '127.0.0.1:6379' }, 
                db      => 1,
                key     => 'test'
            }
    ) or die "Error creating a queue Mir::Queue\n";

    $q->hpush( $hash_item );
}

timethese( 100000, {
    'Queue::Q scalar producer'      => \&qq_str_producer,
    'Mir::Queue scalar producer'    => \&mq_str_producer,
    'Queue::Q hash producer'        => \&qq_hash_producer,
    'Mir::Queue hash producer'      => \&mq_hash_producer
});

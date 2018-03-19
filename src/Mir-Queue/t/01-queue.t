use strict;
use warnings;
use Test::More;

use Mir::Queue ();

ok( my $q = Mir::Queue->create(
        driver  => 'Redis',
        params  => {
            connect => { server => '127.0.0.1:6379' }, 
            db      => 1,
            key     => 'test',
            timeout => 10,
        }), 'new' );
is( ref $q, 'Mir::Queue::Redis', 'Got right object class back');
ok( $q->flush(), 'Queue flushed');
is( $q->count(), 0, 'Got right number of items' );
ok( $q->push('foo'), 'Item pushed');
is( $q->count(), 1, 'Got right number of items' );
ok( $q->push('bar'), 'Item pushed');
is( $q->count(), 2, 'Got right number of items' );
is( $q->pop(), 'foo', 'Got right data from queue' );
is( $q->count(), 1, 'Got right number of items' );
is( $q->pop(), 'bar', 'Got right data from queue' );
is( $q->count(), 0, 'Got right number of items' );

done_testing();

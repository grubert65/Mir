use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'Mir::Stat' ) || print "Bail out!\n";
}

diag( "Testing Mir::Stat $Mir::Stat::VERSION, Perl $], $^X" );
ok(my $foo_counter = Mir::Stat->new( counter => 'foo', select => 10 ), 'new');
ok(my $bar_counter = Mir::Stat->new( counter => 'bar', select => 10 ), 'new');
is($foo_counter->setCount(0), 0, 'setCont');
ok($bar_counter->setCount(10), 'setCont');
ok($foo_counter->incrBy(1), 'incrBy');
ok($foo_counter->incrBy(),  'incrBy even without incr...');
ok($bar_counter->incrBy(5), 'incrBy');
is($foo_counter->value, 2, 'got right data back');
is($bar_counter->value, 15, 'got right data back');
ok($bar_counter->reset(), 'reset');
is($bar_counter->value, 0, 'ok, value resetted' );
ok(my $baz_counter = Mir::Stat->new( counter => 'baz', select => 10 ), 'new');
ok($baz_counter->reset(), 'reset');
is($baz_counter->value, 0, 'ok, got right value back for a brand new counter...');
ok($baz_counter->incrBy(),  'incrBy');
is($baz_counter->value, 1, 'ok, got right value back');

done_testing;

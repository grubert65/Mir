use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mir::Queue::Redis' ) || print "Bail out!\n";
}

diag( "Testing Mir::Queue::Redis $Mir::Queue::Redis::VERSION, Perl $], $^X" );

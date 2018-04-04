use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mir::Channel::Redis' ) || print "Bail out!\n";
}

diag( "Testing Mir::Channel::Redis $Mir::Channel::Redis::VERSION, Perl $], $^X" );

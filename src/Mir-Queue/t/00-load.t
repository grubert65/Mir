use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mir::Queue' ) || print "Bail out!\n";
}

diag( "Testing Mir::Queue $Mir::Queue::VERSION, Perl $], $^X" );

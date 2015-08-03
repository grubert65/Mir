#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mir' ) || print "Bail out!\n";
}

diag( "Testing Mir $Mir::VERSION, Perl $], $^X" );

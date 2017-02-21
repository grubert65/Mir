#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mir::Util::ImageHandler' ) || print "Bail out!\n";
}

diag( "Testing Mir::Util::ImageHandler $Mir::Util::ImageHandler::VERSION, Perl $], $^X" );

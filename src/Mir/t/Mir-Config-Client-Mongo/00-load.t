#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mir::Config::Client::Mongo' ) || print "Bail out!\n";
}

diag( "Testing Mir::Config::Client::Mongo $Mir::Config::Client::Mongo::VERSION, Perl $], $^X" );

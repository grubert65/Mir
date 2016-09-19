#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mir::Plugin::IR::ComputeTermsFrequency' ) || print "Bail out!\n";
}

diag( "Testing Mir::Plugin::IR::ComputeTermsFrequency $Mir::Plugin::IR::ComputeTermsFrequency::VERSION, Perl $], $^X" );

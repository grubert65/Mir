use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Mir::Util::WebUtils' ) || print "Bail out!\n";
}

diag( "Testing Mir::Util::WebUtils $Mir::Util::WebUtils::VERSION, Perl $], $^X" );

done_testing;

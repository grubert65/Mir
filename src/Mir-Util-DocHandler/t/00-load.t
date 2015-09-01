use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Mir::Util::DocHandler' ) || print "Bail out!\n";
}

diag( "Testing Mir::Util::DocHandler $Mir::Util::DocHandler::VERSION, Perl $], $^X" );

ok (my $o = Mir::Util::DocHandler->new(),                                          "new");

done_testing;

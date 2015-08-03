use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Mir::Acq::Fetcher::WU' ) || print "Bail out!\n";
}

diag( "Testing Mir::Acq::Fetcher::WU $Mir::Acq::Fetcher::WU::VERSION, Perl $], $^X" );
ok(my $o = Mir::Acq::Fetcher::WU->new(
        params => {
            city    => 'Genoa',
            country => 'IT',
        }), 'new' );
ok( $o->get_docs(), 'get_docs' );
is( scalar @{$o->docs}, 1, 'got 1 doc...' );
is( ref $o->docs->[0], 'Mir::Doc::WU', 'got right doc type...');
is( $o->docs->[0]->{current_observation}->{display_location}->{city}, 'Genoa', 'got right data back...' );

done_testing;

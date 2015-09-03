use Test::More;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init( $DEBUG );

use_ok('Mir::Acq::Scheduler');

ok(my $o=Mir::Acq::Scheduler->new, 'new');

@ARGV = (
    '--campaign'    => 'weather',
    '--campaign'    => 'news',
);

ok( $o->parse_input_params(), 'parse input params' );
is( scalar @{$o->{campaigns}}, 2, 'got right number of campaigns');
is( $o->{campaigns}->[0], 'weather', 'got right campaign...');

@ARGV = (
    '--campaign'    => 'weather',
    '--campaign'    => 'news',
    '--fetcher'     => 'Instagram',
    '--params'      => '{ "coords":"xx.yy xx.yy"}',
    '--processors'  => 10,
);

ok( $o->parse_input_params(), 'you can pass more than a campaign and single fetchers too...' );
is( scalar @{$o->{campaigns}}, 2, 'got right number of campaigns');
is( $o->{campaigns}->[0], 'weather', 'got right campaign...');
is( $o->{fetchers}->[0], 'Instagram', 'got right fetcher...');
is( $o->processors, 10, 'got right number of processors...');

@ARGV = ( '--processors' => 10 );
is( $o->parse_input_params(), undef, 'at least a campaign or a fetcher has to be configured...');

done_testing;

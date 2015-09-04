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
);

ok( $o->parse_input_params(), 'you can pass more than a campaign and single fetchers too...' );
is( scalar @{$o->{campaigns}}, 2, 'got right number of campaigns');
is( $o->{campaigns}->[0], 'weather', 'got right campaign...');
is( $o->{fetchers}->[0], 'Instagram', 'got right fetcher...');

@ARGV = (
    '--campaign'    => 'weather',
    '--campaign'    => 'news',
    '--params'      => '{ "coords":"xx.yy xx.yy", "cc:"}',
);
is( $o->parse_input_params(), undef, 'Can accept only valid JSON string, when params is provided');

@ARGV = (
    '--fetcher'     => 'Instagram',
    '--params'      => '{ "coords":"xx.yy xx.yy"}',
    '--processors'  => 5,
    '--config'      => 'config/config.yml',
);
ok( $o->parse_input_params(), 'Load a config file this time...');
is( $o->{campaigns}->[0], 'news', 'got right campaign...');
is( $o->{fetchers}->[1], 'WU', 'got right fetcher...');
is( $o->{processors}, 7, 'got right number of processors...');
is( $o->{params}, '{ "coords":"ww.zz zz.ww"}', 'got right params string...');
is( $o->{config_file}, 'config/config.yml', 'got right config_file...');

done_testing;

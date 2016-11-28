use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Log::Log4perl qw( :easy );
use Data::Printer;
use YAML qw(LoadFile);

Log::Log4perl->easy_init( $DEBUG );

BEGIN {
    use_ok( 'Mir::Config::Client' ) || print "Bail out!\n";
    use_ok( 'Mir::Config::Client::YAML' ) || print "Bail out!\n";
}

note( "Testing Mir::Config::Client::YAML $Mir::Config::Client::YAML::VERSION, Perl $], $^X" );

my $docs;
$docs = LoadFile ("./data/config_v2.yaml");

# test second format for configuration params...
ok( my $o = Mir::Config::Client->create(
        driver  => 'YAML',
        params  => { path => './data/config_v2.yaml' }
    ), 'create'
);

ok( $o->connect(), 'connect' );
my $config = $o->config;
is( ref $config, 'ARRAY', 'ok, got right data type back');
is( $config->[0]->{campaign}, 'IR-test', 'ok, got right data back');
# note "The complete configuration file content:";
# p $o->config;

ok(my $params = $o->get_key({campaign=>'IR-test'},{params=>1}), 'get_key');
is(ref $params, 'ARRAY', 'ok, got right data type back...');
is( $params->[0]->{params}->{fetchers}->[0]->{ns}, 'FS', 'ok, got right data back...');

done_testing;

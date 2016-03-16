use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Log::Log4perl qw( :easy );
use Data::Printer;
use JSON;

Log::Log4perl->easy_init( $DEBUG );

BEGIN {
    use_ok( 'Mir::Config::Client' ) || print "Bail out!\n";
    use_ok( 'Mir::Config::Client::JSON' ) || print "Bail out!\n";
}

diag( "Testing Mir::Config::Client::JSON $Mir::Config::Client::JSON::VERSION, Perl $], $^X" );

my $docs;
my $data;
{
    local $/;
    open my $fh, "<./data/config.json";
    $data = <$fh>;
    close $fh;
}

$docs = decode_json $data;

ok( my $o = Mir::Config::Client->create(
        driver  => 'JSON',
        params  => { path => './data/config.json' }
    ), 'create'
);

ok( $o->connect(), 'connect' );
diag "The complete configuration file content:";
p $o->config;

ok(my $fetchers = $o->get_key({tag=>'ACQ'},{fetchers=>1}), 'get_key');
is_deeply( $fetchers->[0]->{fetchers}, $docs->[0]->{fetchers}, 'get_key: got right data back...' );
ok( my $params = $o->get_key({
            tag         => 'IR',
            campaign    => 'IR-test',
        },{
            idx_server  => 1,
            idx_queue_params => 1,
        }
    ), 'get_key' );
is(ref $params, 'ARRAY', 'got right data type back');
my $doc = $params->[0]; # we only need the first doc found...
is_deeply( $doc->{idx_server}, $docs->[1]->{idx_server}, 'got right data back...');
is_deeply( $doc->{idx_queue_params}, $docs->[1]->{idx_queue_params}, 'got right data back...');

done_testing;

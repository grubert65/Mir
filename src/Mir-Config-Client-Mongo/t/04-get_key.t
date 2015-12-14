use Moose;
use Test::More;
use Mir::Config::Client;
use Data::Dumper qw( Dumper );

ok(my $o=Mir::Config::Client->create( 
            driver => 'Mongo', 
            params => {
                host    => 'localhost',
                port    => 27017,
                dbname  => 'MIR',
                section => 'system'
        } ), 'create' );
ok($o->connect(), 'connect');
ok(my $fetchers = $o->get_key({tag=>'ACQ'},{fetchers=>1}), 'get_key');
diag "Fetchers: ";
diag Dumper( $fetchers );

done_testing();

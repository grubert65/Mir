use Moose;
use Test::More;
use Mir::Config::Client;
use Data::Dumper qw( Dumper );

ok(my $o=Mir::Config::Client->create( 
            driver => 'Mongo', 
            params => {
                host    => 'localhost',
                port    => 27017,
                dbname  => 'MIR'
        } ), 'create' );
ok($o->connect(), 'connect');
ok(my $system=$o->get_section('system'), 'get_section');
diag "System section:\n";
diag Dumper( $system );

done_testing();

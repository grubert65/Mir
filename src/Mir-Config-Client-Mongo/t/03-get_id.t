use Moose;
use Test::More;
use Mir::Config::Client;
use Data::Dumper qw( Dumper );
use MongoDB;
use MongoDB::OID;

# populate the foo collection...
my $client = MongoDB::MongoClient->new;
my $db = $client->get_database( 'MIR' );
my $foo = $db->get_collection( 'foo' );
my $id = $foo->insert({"name" => "Foo", "age" => 50 });

ok(my $o=Mir::Config::Client->create( 
            driver => 'Mongo', 
            params => {
                host    => 'localhost',
                port    => 27017,
                dbname  => 'MIR',
                section => 'foo'
        } ), 'create' );
ok($o->connect(), 'connect');
ok(my $obj = $o->get_id( $id ), 'get_id' );
diag Dumper( $obj );

$foo->drop();

done_testing();

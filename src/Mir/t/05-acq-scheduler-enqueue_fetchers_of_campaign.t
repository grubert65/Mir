use Test::More;
use Log::Log4perl qw( :easy );
use JSON;
use MongoDB;
Log::Log4perl->easy_init( $DEBUG );

use_ok(
    'Mir::Acq::Scheduler',
    'Mir::Config::Client'
);

my $data;
my $params;
{
    local $/;
    my $data = <DATA>;
    $params = decode_json( $data );
}

my $client     = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $database   = $client->get_database( 'MIR' );
my $collection = $database->get_collection( 'system' );
my $cursor     = $collection->find({ campaign => 'weather' });
my $id = $collection->insert( $params->[0] ) unless $cursor->count;

# configure the Mir::Config to host the
# right fetchers list...
ok(my $o=Mir::Acq::Scheduler->new(
        campaigns       => [ 'weather' ],
        config_driver   => 'Mongo',
        config_params   => {
            host    => 'localhost',
            port    => 27017,
            dbname  => 'MIR',
            section => 'system'
        }
    ), 'new');

ok( my $num_items = $o->enqueue_fetchers_of_campaign(), 'enqueue_fetchers_of_campaign');
diag "Queued $num_items items...";

done_testing;

__DATA__
[{
  "tag":"ACQ",
  "campaign":"weather",
  "fetchers":[{
    "ns":"WU",
    "params":{
      "city":"Genoa",
      "country":"IT"
    }
  },{
    "ns":"Netatmo",
    "params":{
      "lat_ne": "44.460881",
      "lon_ne": "9.041340",
      "lat_sw": "44.378735",
      "lon_sw": "8.746082"
    }
  }]
}]

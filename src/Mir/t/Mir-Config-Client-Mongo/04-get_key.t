use Moose;
use Test::More;
use Mir::Config::Client;
use Data::Dumper qw( Dumper );
use MongoDB;
use MongoDB::OID;
use JSON;

my $docs;
{
    local $/;
    my $data = <DATA>;
    $docs = decode_json $data;
}


# populate the foo collection...
my $client = MongoDB::MongoClient->new;
my $db = $client->get_database( 'MIR' );
my $foo = $db->get_collection( 'foo' );

my @ids;
foreach (  @$docs ) {
    push @ids, $foo->insert( $_ );
}

ok(my $o=Mir::Config::Client->create( 
            driver => 'Mongo', 
            params => {
                host    => 'localhost',
                port    => 27017,
                dbname  => 'MIR',
                section => 'foo'
        } ), 'create' );
ok($o->connect(), 'connect');
ok(my $fetchers = $o->get_key({tag=>'ACQ'},{fetchers=>1}), 'get_key');
is_deeply( $fetchers->[0]->{fetchers}, $docs->[0]->{fetchers}, 'got right data back...' );
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

$foo->drop();

done_testing();

__DATA__
[
  {
    "tag":"ACQ",
    "campaign":"IR-test",
    "fetchers":[{
      "ns":"FS",
      "params":{
        "node":"localhost",
        "root_dir":".",
        "suffixes":["pm","t"],
        "browse_func":"dir_walk",
        "cache_params":{
            "server":"127.0.0.1:6379",
            "db":1
        },
        "storage_io_params":{
            "io": [ 
                "MongoDB",
                {
                    "key_attr": "id",
                    "host":     "localhost",
                    "database": "MIR",
                    "collection":"IR_test"
                }
            ]
        },
        "idx_queue_params": {
            "server":     "localhost",
            "port":       6379,
            "queue_name": "IDX-IR-Test"
        }
      }
    }]
  },{
    "tag":"IR",
    "campaign":"IR-test",
    "idx_queue_params": {
      "server":     "localhost",
      "port":       6379,
      "queue_name": "IDX-IR-Test"
    },
    "idx_server":{
      "index":"ir-test",
      "type":"doc",
      "ir_params": {
        "nodes": "localhost:9200"
      },
      "mappings":{
         "docs":{
            "_source":{ "compress": 1 },
            "properties":{
                "abspath":{
                    "index": "analyzed",
                    "store": "yes",
                    "type": "string"
                },
                "creation_date":{
                    "index": "not_analyzed",
                    "store": "yes",
                    "type": "date"
                },
                "filename":{
                    "index": "analyzed",
                    "store": "yes",
                    "type": "string"
                },
                "id":{
                    "index": "not_analyzed",
                    "store": "yes",
                    "type": "string"
                },
                "keywords":{
                    "index": "analyzed",
                    "store": "no",
                    "type": "nested"
                },
                "mtime":{
                    "index": "not_analyzed",
                    "store": "yes",
                    "type": "date"
                },
                "mtime_iso8601":{
                    "index": "not_analyzed",
                    "store": "yes",
                    "type": "date"
                },
                "node":{
                    "index": "analyzed",
                    "store": "yes",
                    "type": "string"
                },
                "pages":{
                    "index": "analyzed",
                    "store": "no",
                    "type": "nested"
                },
                "path":{
                    "index": "analyzed",
                    "store": "yes",
                    "type": "string"
                },
                "relpath":{
                    "index": "analyzed",
                    "store": "yes",
                    "type": "string"
                },
                "size":{
                    "index": "not_analyzed",
                    "store": "yes",
                    "type": "integer"
                },
                "status":{
                    "index": "not_analyzed",
                    "store": "yes",
                    "type": "integer"
                },
                "suffix":{
                    "index": "analyzed",
                    "store": "yes",
                    "type": "string"
                },
                "title":{
                    "index": "analyzed",
                    "store": "yes",
                    "type": "string"
                }
             }
          }
       }
    }
  }
]

use Test::More;
use Log::Log4perl qw( :easy );
use JSON;
use MongoDB;
use Data::Printer;
Log::Log4perl->easy_init( $DEBUG );

use_ok( 'Mir::Acq::Scheduler');

my $data;

# configure the Mir::Config to host the
# right fetchers list...
ok(my $o=Mir::Acq::Scheduler->new(
        campaigns       => [ 'CV_local' ],
        config_driver   => 'JSON',
        config_params   => { 
            path => './scripts/cv-local-new-format.json'
        }
    ), 'new');

ok( my $num_items = $o->enqueue_fetchers_of_campaign(), 'enqueue_fetchers_of_campaign');
diag "Queued $num_items items...";
ok(my $num_items = $o->get_number_queue_items(), 'get_number_queue_items' );
p $num_items;

done_testing;

__DATA__
[{
  "tag":"campaign",
  "campaign":"weather",
  "params":{
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
  }
}]

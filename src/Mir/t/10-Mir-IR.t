use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Log::Log4perl qw( :easy );
use Search::Elasticsearch;
use JSON;
use Data::Printer;
use Mir::Store ();

Log::Log4perl->easy_init( $INFO );

BEGIN {
    use_ok( 'Mir::IR' ) || print "Bail out!\n";
    $ENV{MIR_TEMP}='./data/temp';
}

diag( "Testing Mir::IR $Mir::IR::VERSION, Perl $], $^X" );

my $res = `curl "http://localhost:9200"`;
unless ( $res ) {
    diag "It seems that no Elastic server is listening at 0.0.0.0:9200, exiting...\n";
    exit;
}

#
# deleting test index...
my $e = Search::Elasticsearch->new();
if ( $e->indices->exists( index => "ir-test" ) ) {
    $e->indices->delete( index => "ir-test" );
}

my $docs_json;
{
    local $/;
#    open my $fh, "<./data/docs_ir.json";
    open my $fh, "<./data/hop.json";
    $docs_json = <$fh>;
    close $fh;
}
my $items = decode_json $docs_json;

my $store = Mir::Store->create( 
    driver => 'MongoDB',
    params => {
        host        => 'localhost',
        database    => 'MIR',
        collection  => 'IR_test'
});
$store->connect() or die "Error connecting to the Store";
$store->drop();

ok( my $o = Mir::IR->new(
    campaign      => 'IR-test',
    config_driver => 'JSON',
    config_params => { path => './data/config_v2.json' }
), 'new' );

ok( $o->config(), 'config' );

foreach my $item ( @$items ) {
    $store->insert( $item );
}

ok( $o->process_new_items(), 'process_new_items');

sleep(1);
# ok, now look for all docs that have to do with
# iterators, using the raw ES client
ok($res = $o->e->search(
        index => 'ir-test',
        body  => {
            query => {
                multi_match => { 
                    query => 'iterator',
                    fields=> ["title^2", "keywords^2", "text"]
                }
            }
        }
    ), 'search' );
is ($res->{hits}->{total}, 2, 'ok, got right number of docs back');

done_testing;

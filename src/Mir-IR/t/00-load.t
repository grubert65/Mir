use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Log::Log4perl qw( :easy );
use Search::Elasticsearch;
use JSON;

Log::Log4perl->easy_init( $DEBUG );

BEGIN {
    use_ok( 'Mir::IR' ) || print "Bail out!\n";
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
    open my $fh, "<./data/docs_ir.json";
    $docs_json = <$fh>;
    close $fh;
}

ok( my $o = Mir::IR->new(
    campaign        => 'IR-test',
    config_driver   => 'JSON',
    config_params   => { path => './data/config.json' }
), 'new' );

ok( $o->config(), 'config' );

my $items = decode_json $docs_json;
foreach my $item ( @$items ) {
    ok(my $ret = $o->_index_item( $item ), "_index_item");
}

done_testing;

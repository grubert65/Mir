use strict;
use warnings;
use Test::More;
use Data::Printer;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($DEBUG);

BEGIN {
    use_ok('Mir::Mon');
}

ok( my $o = Mir::Mon->new(
        campaign        => 'SampleCampaign',
        config_driver   => 'JSON',
        config_params   => {path => "./scripts/sample-campaign.json"}
    ), 'new' );

is( $o->number_items_acq_processor_queue(), 0, 'number-items-acq-processor-queue' );
ok( my $stores = $o->number_docs_store(), 'number-docs-store');
diag "\nStores:\n";
p $stores;
ok( $o->number_keys_store_cache(), 'number-keys-store-cache');
ok( $o->number_items_ir_queues(), 'number-items-ir-queues' );
ok( $o->number_docs_indexes(), 'number-docs-indexes' );

done_testing;

use Test::More;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init( $DEBUG );

use_ok('Mir::Acq::Scheduler');

# configure the Mir::Config to host the
# right fetchers list...

ok(my $o=Mir::Acq::Scheduler->new, 'new');

@ARGV = qw(
    --campaign
    weather
);

ok( $o->parse_input_params(), 'parse input params' );
ok( my $num_items = $o->enqueue_fetchers_of_campaign(), 'enqueue_fetchers_of_campaign');
diag "Queued $num_items items...";

done_testing;

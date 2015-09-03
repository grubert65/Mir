use Test::More;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init( $DEBUG );

use_ok('Mir::Acq::Scheduler');

# configure the Mir::Config to host the
# right fetchers list...

ok(my $o=Mir::Acq::Scheduler->new, 'new');

@ARGV = qw(
    '--campaign'
    'weather'
    '--processors'
    '3'
);

ok( $o->parse_input_params(), 'parse input params' );
is( $o->enqueue_fetchers_of_campaign(), 3, 'enqueue_fetchers_of_campaign');

@ARGV = ( '--fetcher' => 'WU' );
ok( $o->parse_input_params(), 'parse input params' );
is( $o->enqueue_fetchers_of_campaign(), 1, 'enqueue_fetchers_of_campaign');

done_testing;

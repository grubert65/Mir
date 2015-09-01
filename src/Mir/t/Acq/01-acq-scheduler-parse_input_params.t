use Test::More;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init( $DEBUG );

use_ok('Mir::Acq::Scheduler');

ok(my $o=Mir::Acq::Scheduler->new, 'new');

@ARGV = qw(
    '--campaign'
    'weather'
    '--processors'
    '3'
);

ok( $o->parse_input_params(), 'parse input params' );

@ARGV = qw(
    '--campaign'
    'weather'
    '--fetcher'
    'foo'
);

ok( $o->parse_input_params(), 'you can pass a campaign and single fetchers too...' );

@ARGV = ( '--processors' => 10 );
is( $o->parse_input_params(), undef, 'at least a campaign or a fetcher has to be configured...');

done_testing;

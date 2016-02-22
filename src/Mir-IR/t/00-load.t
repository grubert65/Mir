use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Mir::Acq::Fetcher::FS;
use Mir::Config::Client;
use Log::Log4perl qw( :easy );

Log::Log4perl->easy_init( $DEBUG );

BEGIN {
    use_ok( 'Mir::IR' ) || print "Bail out!\n";
}

diag( "Testing Mir::IR $Mir::IR::VERSION, Perl $], $^X" );

# to test Mir::IR we need first to launch a fetcher (for example the
# Mir::Acq::Fetcher::FS) that creates some docs in a configured 
# mongo folder and enqueue items in the IR queue...
my $config_obj = Mir::Config::Client->create(
    driver  => 'JSON',
    params  => { path => './data/config.json' },
);

$config_obj->connect();

my $fetchers = $config_obj->get_key({
        tag     => 'ACQ',
        campaign=> 'IR-test',

    },{
        fetchers => 1,
    }
);

my $f = Mir::Acq::Fetcher::FS->new( $fetchers->[0]->{fetchers}->[0]->{params} )
    or die "Error getting an FS fetcher...\n";

$f->fetch();
if ( $f->ret ) {
    foreach ( @{ $f->docs } ) {
        diag "Got $_->{path}\n";
    }
}

ok( my $o = Mir::IR->new(
    campaign        => 'IR-test',
    config_driver   => 'JSON',
    config_params   => { path => './data/config.json' }
), 'new' );

ok( $o->config(), 'config' );

ok( $o->process_items_in_queue(), 'process_items_in_queue' );

done_testing;

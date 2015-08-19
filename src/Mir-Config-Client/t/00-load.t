use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
use Data::Dumper  qw(Dumper);

Log::Log4perl->easy_init($DEBUG);

BEGIN {
    use_ok( 'Mir::Config::Client' ) || print "Bail out!\n";
}

diag( "Testing Mir::Config::Client $Mir::Config::Client::VERSION, Perl $], $^X" );

diag "Connecting to Mir::Config...";
diag "host: localhost";
diag "port: 5000";
ok(my $o=Mir::Config::Client->new( 
#        host    => 'localhost',
#        port    => 5000,
        ), 'new' );
ok(my $component_profile = $o->get_item( 
        section => 'system',
        item => 'ACQ' ), 'get_item' );
diag "Item ACQ:";
diag Dumper( $component_profile );
ok(my $resource = $o->get_resource( 
        section => 'system',
        item => 'ACQ',
        resource => 'fetchers'
), 'get_resource' );
diag "Resource 'fetchers':";
diag Dumper( $resource );

done_testing();

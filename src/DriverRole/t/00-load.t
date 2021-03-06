use Test::More;
use Moose;
use CustomInterface;

BEGIN {
    use_ok( 'DriverRole' ) || print "Bail out!\n";
}

diag( "Testing DriverRole $DriverRole::VERSION, Perl $], $^X" );
ok( my $o = CustomInterface->create( driver => 'Driver'), 'create');
is( ref $o, 'CustomInterface::Driver', 'got right class obj back');
ok( $o->bar(), 'bar driver method implementation called' );

ok( my $o2 = CustomInterface->create( 
        driver => 'Driver',
        params => { baz => 1 }
    ), 'create');
is( ref $o2, 'CustomInterface::Driver', 'got right class obj back');
ok( $o2->bar(), 'bar driver method implementation called' );

# now a wrong driver creation procedure, passing a single scalar
# as parameter, the driver gets actually called without params...
ok( my $o3 = CustomInterface->create( 
        driver => 'Driver',
        params => 1
    ), 'create');
is( ref $o3, 'CustomInterface::Driver', 'got right class obj back');
ok( $o3->bar(), 'bar driver method implementation called' );

# Another wrong driver istantiation, params should be an
# hash ref not an array ref...
ok( my $o4 = CustomInterface->create( 
        driver => 'Driver',
        params => [ qw( foo bar baz ) ]
    ), 'create');
is( ref $o4, 'CustomInterface::Driver', 'got right class obj back');
ok( $o4->bar(), 'bar driver method implementation called' );



done_testing;

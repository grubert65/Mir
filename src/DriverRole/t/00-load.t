use Test::More;
use Moose;
use Foo;

BEGIN {
    use_ok( 'DriverRole' ) || print "Bail out!\n";
}

diag( "Testing DriverRole $DriverRole::VERSION, Perl $], $^X" );
ok( my $o = Foo->create( driver => 'Driver'), 'create');
is( ref $o, 'Foo::Driver', 'got right class obj back');
ok( $o->bar(), 'bar driver method implementation called' );

done_testing;

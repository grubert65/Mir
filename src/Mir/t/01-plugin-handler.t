use Test::More;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($DEBUG);

BEGIN {
    use_ok( 'Mir::R::PluginHandler' );
}

ok( my $o = Foo->new(), 'new' );
ok($o->register_plugins({
            'hook' => {
                Foo => { a1 => 'v1' },
                Bar => { a2 => 'v2' }
            }
        }), 'register_plugins' );

my $foo = {};
ok($o->call_registered_plugins({
        hook          => 'hook',
        input_params  => { foo => 'bar' },
        output_params => $foo,
    }
), 'call_registered_plugins');

done_testing;

package Mir::Plugin::Foo;
use Moose;
with 'Mir::R::Plugin';
has 'a1' => ( is => 'rw', isa => 'Str', required => 1 );
sub run { 
    print "Plugin Foo called!\n" 
};

package Mir::Plugin::Bar;
use Moose;
with 'Mir::R::Plugin';
has 'a2' => ( is => 'rw', isa => 'Str', required => 1 );
sub run { print "Plugin Bar called!\n" };

1;

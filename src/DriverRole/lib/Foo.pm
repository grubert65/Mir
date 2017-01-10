package Foo;
use Moose::Role;
with 'DriverRole';

requires 'bar';


package Foo::Driver;
use Moose;
use feature 'say';
with 'Foo';

has 'baz' => ( is => 'rw', isa => 'Num', default => 0 );

sub bar {
    my $self = shift;
    say 'Driver called';
    say "Baz: ".$self->baz;
}

1;

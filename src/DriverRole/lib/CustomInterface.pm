package CustomInterface;
use Moose::Role;
with 'DriverRole';

# Interface definition...
requires 'bar';


package CustomInterface::Driver;
use Moose;
use feature 'say';
with 'CustomInterface';

has 'baz' => ( is => 'rw', isa => 'Num', default => 0 );

sub bar {
    my $self = shift;
    say 'Driver called';
    say "Baz: ".$self->baz;
}

1;

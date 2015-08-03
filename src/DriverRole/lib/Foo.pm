package Foo;
use Moose::Role;
with 'DriverRole';

requires 'bar';


package Foo::Driver;
use Moose;
use feature 'say';
with 'Foo';

sub bar {
    say 'Driver called';
}

1;

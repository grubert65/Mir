package Mir::Queue;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Queue - A base class to handle simple queues

=head1 VERSION

0.01

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    use Mir::Queue ();

    my $q = Mir::Queue->create(
        driver  => 'Redis',
        params  => {
            connect => { server => '127.0.0.1:6379' }, 
            db      => 1,
            key     => 'test'
            timeout => 10,
        });

    # flush queue content...
    $q->flush();

    # push next item in queue...
    $q->push('bar');


    # pop first item in queue or wait (for timeout)
    # for next item...
    $my $item = q->pop();

=head1 DESCRIPTION

A very simple class to handle a basic queue. 
Don't use the base class (the interface) but one of the 
implemented drivers.
The interface comes with the Redis driver.
The Redis driver supports multiple consumers, please read
the specific driver implementation details for its features.


=head1 AUTHOR

Marco Masetti (marco.masetti @ softeco.it )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

#========================================================================
use Moose::Role;
with 'DriverRole';

requires 'flush';   # deletes all elements in queue
requires 'spush';    # add a scalar element
requires 'spop';     # removes and returns the last element as scalar
requires 'hpush';    # add an hash element
requires 'hpop';     # removes and returns the last element as hash
requires 'count';   # returns the number of elements in queue

1;

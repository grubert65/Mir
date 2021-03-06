package Mir::Queue;
use Moose::Role;
with 'DriverRole';

requires 'flush';   # deletes all elements in queue
requires 'push';    # add a scalar element
requires 'pop';     # removes and returns the last element as scalar
requires 'count';   # returns the number of elements in queue

#============================================================= -*-perl-*-

=head1 NAME

Mir::Queue - A Mir role to be consumed by any queue driver

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
    # item can be any scalar
    # if not a string or a number it gets
    # JSON-encoded
    $q->push('bar');

    # pop first item in queue or wait (for timeout)
    # for next item...
    $my $item = $q->pop();

    # get the number of items in queue
    my $count = $q->count();

=head1 DESCRIPTION

A very simple role to handle a basic queue. 
Don't use this role (the interface) but one of the 
implemented drivers.


=head1 AUTHOR

Marco Masetti (grubert65 at gmail.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

#========================================================================
1;

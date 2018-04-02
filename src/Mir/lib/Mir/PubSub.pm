package Mir::PubSub;
use Moose::Role;
with 'DriverRole';

requires 'push';    # add a scalar element
requires 'pop';     # removes and returns the last element as scalar

#============================================================= -*-perl-*-

=head1 NAME

Mir::PubSub - A role for any Publish/Subscribe client

=head1 VERSION

0.01

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    use Mir::PubSub ();

    my $c = Mir::PubSub->create(
        driver  => 'Redis',
        params  => {
            connect => { server => '127.0.0.1:6379' }, 
            db      => 1,
            timeout => 10,
        });

    # Subscribe for a topic
    # leave a callback that will be called any time a
    # message on the topic will be published
    $c->subscribe( 'topic_1', &callback );

    # Publish a message on a channel
    # a msg can be any scalar, if not a plain string
    # it gets JSON-encoded
    $c->publish('topic_1', $msg)
        or die "Error publishing a message";

=head1 DESCRIPTION

A very simple role to handle a basic pubsub channel.. 
Don't use this role (the interface) but one of the 
implemented drivers.


=head1 AUTHOR

Marco Masetti (grubert65 at gmail.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2018 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

#========================================================================
1;

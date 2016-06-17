package Mir::Stat;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Stat - A simple class to keep statistical counters 

=head1 VERSION

0.02

=cut

use vars qw( $VERSION );
$VERSION='0.02';

=head1 SYNOPSIS

    use Mir::Stat;

    # get a stat object for a given counter, keep counter key 
    # on selected Redis database
    my $foo_counter = Mir::Stat->new( 
        counter => 'foo', 
        value   => 0, # set the initial value of the counter...
        server  => 'redis.example.com:8080', # defaults to '127.0.0.1:6379' 
        select  => 10 
    );

    # set counter to an initial value
    # (if not passed at costruction time...)
    $foo_counter->setCount(0);

    # increment counter by a given quantity
    $foo_counter->incrBy(1);

    # get counter value back
    my $value = $foo_counter->get();

=head1 DESCRIPTION

A simple class to handle counters.

=head1 AUTHOR

Marco Masetti (marco.masetti @ softeco.it )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SUBROUTINES/METHODS

=cut

#========================================================================
use Moose;
use namespace::autoclean;
use Redis;

has 'counter'   => ( is => 'rw', isa => 'Str', required => 1 );
has 'server'    => ( is => 'rw', isa => 'Str', default => sub { return '127.0.0.1:6379' } );
has 'select'    => ( is => 'rw', isa => 'Int', default => sub { return 0 } );
has 'value'     => ( is => 'ro', isa => 'Int', lazy => 1, builder => 'get_value', writer => 'set_value' );
has 'redis'     => ( is => 'ro', isa => 'Redis', lazy => 1, builder => '_get_redis' );

#=============================================================

=head2 setCount

=head3 INPUT

    $value : the new value of the counter

=head3 OUTPUT

The set Redis operation output.

=head3 DESCRIPTION

Sets the counter to the passed value.

=cut

#=============================================================
sub setCount {
    my ( $self, $value ) = @_;
    $self->redis->set( $self->counter => $value );
    $self->set_value( $self->get_value() );
}

#=============================================================

=head2 incrBy

=head3 INPUT

    $increment : the increment to add to counter value (1 by default).

=head3 OUTPUT

=head3 DESCRIPTION

Increment the counter by the passed value (or by 1 if not set).
Resets first the counter if not yet set...

=cut

#=============================================================
sub incrBy {
    my ( $self, $increment ) = @_;

    $increment //= 1;
    $self->redis->incrby($self->counter, $increment);
    $self->set_value( $self->get_value() );
}

#=============================================================

=head2 reset

=head3 INPUT

=head3 OUTPUT

The Redis set operation output

=head3 DESCRIPTION

Resets the counter to 0.

=cut

#=============================================================
sub reset {
    my $self = shift;
    $self->redis->set( $self->counter => 0 );
    $self->set_value( 0 );
    return 1;
}

#=============================================================

=head2 _get_redis

=head3 INPUT

=head3 OUTPUT

A Redis object

=head3 DESCRIPTION

Internal method to get a new Redis object.

=cut

#=============================================================
sub _get_redis {
    my $self = shift;
    my $r = Redis->new( server => $self->server );
    $r->select( $self->select );
    return $r;
}

#=============================================================

=head2 get_value

=head3 INPUT

=head3 OUTPUT

The value of the counter

=head3 DESCRIPTION

Reads the value of the counter

=cut

#=============================================================
sub get_value {
    my $self = shift;
    return $self->redis->get( $self->counter ) || 0;
}

1;

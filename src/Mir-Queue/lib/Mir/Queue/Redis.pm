package Mir::Queue::Redis;

#============================================================= -*-perl-*-

=head1 NAME

Mir::Queue::Redis - Redis driver that implements the interface Mir::Queue.

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

Refer to base class description.


=head1 AUTHOR

Marco Masetti (marco.masetti @ softeco.it )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SUBROUTINES/METHODS

=cut

#========================================================================
use Moose;
use Redis ();

with 'Mir::Queue';

has 'r' => (
    is  => 'rw',
    isa => 'Redis',
    lazy=> 1,
    default => sub { Redis->new }
);

has 'key'       => (is => 'rw', isa => 'Str', default => 'default_queue' );
has 'timeout'   => (is => 'rw', isa => 'Int', default => 0 );

#=============================================================

=head2 BUILD

=head3 INPUT

    $params: connection parameters

=head3 OUTPUT

=head3 DESCRIPTION

Connects to Redis and returns a queue object

=cut

#=============================================================
sub BUILD {
    my ( $self, $params ) = @_;
    $self->r( Redis->new( %{$params->{connect}} ) )
        or die "Error getting a Redis obj";
    $self->key( $params->{key} ) if ( $params->{key} );
    $self->timeout( $params->{timeout} ) if ( $params->{timeout} );
    $self->r->select( $params->{db} ) if ( $params->{db} );
}


#=============================================================

=head2 flush

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

Deletes all messages in the queue

=cut

#=============================================================
sub flush {
    my $self = shift;
    $self->r->flushdb();
}

#=============================================================

=head2 push

=head3 INPUT

    $item

=head3 OUTPUT

=head3 DESCRIPTION

Add an item to the queue

=cut

#=============================================================
sub push {
    my ( $self, $item ) = @_;
    $self->r->lpush( $self->key, $item );
}

#=============================================================

=head2 pop

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

Pops out the first item in the queue

=cut

#=============================================================
sub pop {
    my $self = shift;
    my $item = $self->r->brpop( $self->key, $self->timeout );
    return $item->[1];
}

#=============================================================

=head2 count

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

Returns the number of items in the queue

=cut

#=============================================================
sub count {
    my $self = shift;
    return $self->r->llen( $self->key );
}

no Moose;
__PACKAGE__->meta->make_immutable;


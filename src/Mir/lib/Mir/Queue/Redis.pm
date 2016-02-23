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

    # push next scalar item in queue...
    $q->spush('bar');

    # pop first item in queue as scalar or wait (for timeout)
    # for next item...
    $my $item = q->spop();

    # push next hash item in queue...
    $q->hpush('bar');

    # pop first item in queue as hash or wait (for timeout)
    # for next item...
    $my $item = q->hspop();

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
use JSON qw( encode_json decode_json );

with 'Mir::Queue';

has 'r' => (
    is  => 'rw',
    isa => 'Redis',
    lazy=> 1,
    default => sub { Redis->new }
);

has 'key'       => (is => 'rw', isa => 'Str', default => 'default_queue' );
has 'timeout'   => (is => 'rw', isa => 'Int', default => 0 );

sub BUILD {
    my ( $self, $params ) = @_;
    $self->r( Redis->new( %{$params->{connect}} ) )
        or die "Error getting a Redis obj";
    $self->key( $params->{key} ) if ( $params->{key} );
    $self->timeout( $params->{timeout} ) if ( $params->{timeout} );
    $self->r->select( $params->{db} ) if ( $params->{db} );
}


sub flush {
    my $self = shift;
    $self->r->flushdb();
}

sub spush {
    my ( $self, $item ) = @_;
    $self->r->lpush( $self->key, $item );
}

sub spop {
    my $self = shift;
    my $item = $self->r->brpop( $self->key, $self->timeout );
    return $item->[1];
}

sub hpush {
    my ( $self, $item ) = @_;
    my $s = encode_json( $item );
    $self->r->lpush( $self->key, $s );
}

sub hpop {
    my $self = shift;
    my $item = $self->r->brpop( $self->key, $self->timeout );
    return decode_json( $item->[1] );
}


sub count {
    my $self = shift;
    return $self->r->llen( $self->key );
}

no Moose;
__PACKAGE__->meta->make_immutable;


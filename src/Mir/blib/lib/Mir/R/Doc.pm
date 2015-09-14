package Mir::R::Doc;
#============================================================= -*-perl-*-

=head1 NAME

Mir::R::Doc : ruolo base per la gestione di un documento

=head1 VERSION

0.0.1

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    package MyDoc;
    use Moose;
    with 'Mir::R::Doc';

=head1 DESCRIPTION

Ruolo che implementa la logica base di un documento.

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
use Moose::Role;
use Data::GUID;
use DateTime;

use MooseX::Storage;
with Storage( 'format' => 'JSON' );

use namespace::autoclean;

# stato del documento
use enum qw( 
    NEW 
    INDEXED
    DELETED
);

has 'id' => ( 
    is => 'rw', 
    isa => 'Str',
    lazy    => 1,
    default => sub {
        my $guid = Data::GUID->new();
        $guid->as_string;
    }
);

has 'title'         => ( is => 'rw', isa => 'Str' );
has 'text'          => ( is => 'rw', isa => 'Str' );
has 'source'        => ( is => 'rw', isa => 'Str' );
has 'creation_date' => ( 
    is      => 'ro',
    isa     => 'Str',
    default => sub { DateTime->now->iso8601() },
);

# TODO : questo e' forse inutile, dal namespace...
#has 'type'   => ( is => 'rw', isa => 'Str' );
has 'status'        => ( 
    is      => 'rw',
    isa     => 'Int',
    default => sub { NEW },
);

# documento padre
has 'father'    => ( is => 'rw', isa => 'Obj' );

# documenti figli
has 'children'  => ( is => 'rw', isa => 'ArrayRef[Obj]' );

#=============================================================

=head2 add_child

=head3 INPUT

    $child

=head3 OUTPUT

=head3 DESCRIPTION

Aggiunge l'oggetto passato all'array children.

=cut

#=============================================================
sub add_child {
    my ( $self, $child ) = @_;
    push @{$self->{children}}, $child;
}
1;

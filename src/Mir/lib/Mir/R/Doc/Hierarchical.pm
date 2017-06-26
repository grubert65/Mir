package Mir::R::Doc::Hierarchical;
#============================================================= -*-perl-*-

=head1 NAME

Mir::R::Doc::Hierarchical - Role to be consumed by any hierarchical doc.

=head1 VERSION

0.0.1

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    use Something;
    with 'Mir::R::Doc::Hierarchical;

    my $o = Something->new();
    $o->father( $father_obj );
    $o->add_child( $child );

=head1 DESCRIPTION

This role can help organizing hierarchical documents.

=head1 AUTHOR

Marco Masetti ( grubert65 at gmail.com )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017 Marco Masetti (grubert65 at gmail.com).

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SUBROUTINES/METHODS

=cut

#========================================================================
use Moose::Role;
with 'Mir::R::Doc';

has 'father'    => ( is => 'rw', isa => 'Obj' );
has 'children'  => ( is => 'rw', isa => 'ArrayRef[Obj]' );

#=============================================================

=head2 add_child

=head3 INPUT

    $child

=head3 OUTPUT

=head3 DESCRIPTION

Add the passed object to the list of children

=cut

#=============================================================
sub add_child {
    my ( $self, $child ) = @_;
    push @{$self->{children}}, $child;
}

1;

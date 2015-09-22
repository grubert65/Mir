package Mir::R::Doc::Artifact;
#============================================================= -*-perl-*-

=head1 NAME

Mir::R::Doc::Artifact - Role for any document (profile) with an
artifact annexed (a physical file/folder stored somewhere).

=head1 VERSION

0.0.1

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    use Something;
    with 'Mir::R::Doc::Artifact;

    my $o = Something->new();
    $o->path( '...' );
    $o->fileformat( 'Html' );# the format (eventually) identifies a sub-role...
    $o->filename( '...' );  # complete filename including suffix
    $o->suffix('...');
    $o->creation_date()     # the ISO-8601 encoded artifact creation date
                            # this attribute actually comes from the 
                            # Mir::R::Doc role

=head1 DESCRIPTION

Questo ruolo aggiunge le proprieta' e caratteristiche 
tipiche di un oggetto sul web.

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
use DateTime;
with 'Mir::R::Doc';

has 'path'      => ( is => 'rw', isa => 'Str' );
has 'filename'  => ( is => 'rw', isa => 'Str' );
has 'suffix'    => ( is => 'rw', isa => 'Str' );
has 'fileformat'=> ( is => 'rw', isa => 'Str' );

#=============================================================

=head2 download

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

Downloads the artifact and updates the artifact metadata
section

=cut

#=============================================================
sub download {
    my $self = shift;
}

1;

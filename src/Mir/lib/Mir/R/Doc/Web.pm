package Mir::R::Doc::Web;
#============================================================= -*-perl-*-

=head1 NAME

Mir::R::Doc::Web - ruolo per ogni documento sul web

=head1 VERSION

0.0.1

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    use Something;
    with 'Mir::R::Doc::Web;

    my $o = Something->new();
    $o->url( '...' );
    $o->format( 'Html' ); # the format (eventually) identifies a sub-role...

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
with 'Mir::R::Doc';

has 'url'    => ( is => 'rw', isa => 'Str' );
has 'format' => ( is => 'rw', isa => 'Str' );

1;

package Mir::R::Doc;
#============================================================= -*-perl-*-

=head1 NAME

Mir::R::Doc : base role for any document type

=head1 VERSION

0.0.1

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    package MyDoc;
    use Moose;
    with 'Mir::R::Doc';

=head1 DESCRIPTION

This role implements the basic logic for any document.

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
use namespace::autoclean;
use MooseX::Storage;
with 'Mir::R::Doc::Bare', Storage( 'format' => 'JSON' );

has 'title'  => ( is => 'rw', isa => 'Str' );
has 'source' => ( is => 'rw', isa => 'Str' );

1;

package Mir::R::Doc::Bare;
#============================================================= -*-perl-*-

=head1 NAME

Mir::R::Doc::Bare : base and bare role for any document type

=head1 VERSION

0.0.1

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    package MyDoc;
    use Moose;
    with 'Mir::R::Doc::Bare';

=head1 DESCRIPTION

This role implements the basic logic for any document.
A document that consumes this role just gets an id and
the creation_time attr for free.

=head1 AUTHOR

Marco Masetti (grubert65 @ gmail.com)

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

# doc status
has 'status' => ( 
    is      => 'rw',
    isa     => 'Int',
    default => sub { 0 }, # default status for any new document
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

has 'creation_date' => ( 
    is      => 'ro',
    isa     => 'Str',
    default => sub { DateTime->now->iso8601() },
);

1;

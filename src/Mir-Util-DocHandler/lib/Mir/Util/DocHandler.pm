package Mir::Util::DocHandler;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler - A class to handle a good range of doc types.

=head1 VERSION

0.11

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

    use Mir::Util::DocHandler;

    # get a driver for the proper doc type...
    my $dh = Mir::Util::DocHandler->create( driver => 'txt' );

    # open the doc...
    $dh->open_doc("./lib/Mir/Util/DocHandler.pm");

    # get the number of document pages...
    # (for some driver - as txt, image - this is meaningless...)
    my $pages = $dh->get_num_pages();

    # get page text and confidence...
    my ($text,$conf) = $dh->page_text(1);

=head1 DESCRIPTION

A class to handle a good range of doc types.
This class consumes the DriverRole and the Mir::Util::R::DocHandler roles.

=head1 AUTHOR

Marco Masetti (marco.masetti @ softeco.it )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

#========================================================================
use Moose;
use namespace::autoclean;
with 'DriverRole', 'Mir::Util::R::DocHandler';

#=============================================================

=head2 get_num_pages

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

Returns the number of doc pages.
To be implemented by each single driver.

=cut

#=============================================================
sub get_num_pages {
    my ($self) = shift;
    return 1;
}

#=============================================================

=head2 page_text

=head3 INPUT

    $page_num   : page number

=head3 OUTPUT

An array

=head3 DESCRIPTION

Gets page text along with confidence for the passed page number
This method is implemented by each specific driver.

=cut

#=============================================================
sub page_text {
    my ( $self, $page_num ) = @_;
    return ( "", 100 );
}
1;

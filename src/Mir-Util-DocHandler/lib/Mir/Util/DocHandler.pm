package Mir::Util::DocHandler;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler - A class to handle a good range of doc types.

=head1 VERSION

0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    use Mir::Util::DocHandler;

    # get a driver for the proper doc type...
    my $dh = Mir::Util::DocHandler->create( driver => 'txt' );

    # open the doc...
    $dh->open_doc("./lib/Mir/Util/DocHandler.pm");

    # get the number of document pages...
    # (for some driver - as txt, image - this is meaningless...)
    my $pages = $dh->pages();

    # get page text and confidence...
    my ($text,$conf) = $dh->page_text(1);

=head1 DESCRIPTION

A class to handle a good range of doc types.

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
with 'DriverRole';


1;

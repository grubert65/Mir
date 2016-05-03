package Mir::Util::DocHandler;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler - A class to handle a good range of doc types.

=head1 VERSION

0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Mir::Util::DocHandler;

    my $dh = Mir::Util::DocHandler->create( driver => 'txt' );

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

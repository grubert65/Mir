package Mir::Store;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Store - Mir class to handle doc profiles persistency

=head1 VERSION

0.01

=cut

# HISTORY
# 0.01 | 14.05.2015 | Draft
our $VERSION='0.01';

=head1 SYNOPSIS

    # handling something...
    use Mir::Store;
    my $store = Mir::Store->create( driver => 'Something' );
    my $dh = $store->connect( $connect_params );
    my $doc = $dh->find_by_id('....');
    $dh->insert( $doc ) or die;

=head1 DESCRIPTION

Classe base per la gestione del data store. Lo store e' MongoDB.
Questa classe viene estesa dalle varie classi (una per ogni tipo
di documento da gestire). Le varie classi devono valorizzare $self->db_name.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

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
use namespace::autoclean;
with 'DriverRole';

1;

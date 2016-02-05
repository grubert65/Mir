package Mir::IR;
#============================================================= -*-perl-*-

=head1 NAME

Mir::IR - frontend for the Elastic Search indexer.

=head1 VERSION

0.01

=head1 SYNOPSIS

    use Mir::IR ();

    my $ir = Mir::IR->new();

    # basically you get what Search::ElasticSearch provides
    # plus:
    #

=head1 DESCRIPTION

This class extends the base Search::Elasticsearch to provides utility methods.

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
use Moo;
use Search::Elasticsearch;
use namespace::clean;

extends 'Search::Elasticsearch';

1;

 


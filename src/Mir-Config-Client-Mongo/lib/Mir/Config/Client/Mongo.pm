package Mir::Config::Client::Mongo;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Config::Client::Mongo - implements the Mir::R::Config role 
on a Mongo data store.

=head1 VERSION

0.01

=head1 SYNOPSIS

    use Mir::R::Config;

    my $o = Mir::R::Config->create( driver => 'Mongo' );

    $o->connect(
        host    => 'localhost',
        port    => 5000,
        database=> 'MIR'
    ) or die "Error getting a Mir::Config::Client::Mongo obj\n";

    # retrieves the complete content of a configuration section...
    my $section = $o->get_section( $collection_name );

=head1 DESCRIPTION

A class that handles Mir::Config sections on a Mongo data store.

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
use MongoDB;

with 'Mir::R::Config';

has 'host' => ( is => 'rw', isa => 'Str', default => 'localhost' );
has 'port' => ( is => 'rw', isa => 'Int', default => 27017 );
has 'dbname' => ( is => 'rw', isa => 'Str', default => 'MIR' );
has 'database' => ( 
    is => 'ro', 
    isa => 'MongoDB::Database',
    writer => '_set_database'
);

sub connect {
    my  $self = shift;

    my $client     = MongoDB::MongoClient->new(
        host => $self->host,
        port => $self->port
    ) or die "Error getting a MongoClient obj\n";

    $self->_set_database( $client->get_database( $self->dbname ) )
        or die "Error getting a MongoDB::Database obj\n";
}

sub get_section {
    my ( $self, $section ) = @_;
    return undef unless $section;

    my $collection = $self->database->get_collection( $section )
        or die "Error getting section $section\n";

    my $cursor = $collection->find();
    
    return [ $cursor->all ];
}

sub get_id {
    
    return 1;
}

sub get_key {

    return 1;
}

1; # End of Mir::Config::Client::Mongo

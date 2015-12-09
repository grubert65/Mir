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
use MongoDB::OID;

with 'Mir::R::Config';

has 'host' => ( is => 'ro', isa => 'Str', default => 'localhost' );
has 'port' => ( is => 'ro', isa => 'Int', default => 27017 );
has 'dbname' => ( is => 'ro', isa => 'Str', default => 'MIR' );
has 'section'=> ( is => 'rw', isa => 'Str' );

has 'database' => ( 
    is => 'ro', 
    isa => 'MongoDB::Database',
    writer => '_set_database'
);

has 'collection' => (
    is  => 'ro',
    isa => 'MongoDB::Collection',
    writer => '_set_collection'
);

sub connect {
    my  $self = shift;

    my $client     = MongoDB::MongoClient->new(
        host => $self->host,
        port => $self->port
    ) or die "Error getting a MongoClient obj\n";

    $self->_set_database( $client->get_database( $self->dbname ) )
        or die "Error getting a MongoDB::Database obj\n";

    if ( $self->section ) {
        $self->_set_collection( $self->database->get_collection( $self->section ) )
            or die "Error getting section $self->{section}\n";
    }
}

sub get_section {
    my ( $self, $section ) = @_;

    if ( $section ) {
        $self->_set_collection( $self->database->get_collection( $section ) )
            or die "Error getting section $section\n";
    }

    return undef unless $self->collection;
    my $cursor = $self->collection->find();
    
    return [ $cursor->all ];
}

sub get_id {
    my ( $self, $id ) = @_;
    
    $DB::single=1;
    return undef unless $self->collection;
    my $obj = $self->collection->find_one({ _id => $id });

    return $obj;
}

sub get_key {

    return 1;
}

1; # End of Mir::Config::Client::Mongo

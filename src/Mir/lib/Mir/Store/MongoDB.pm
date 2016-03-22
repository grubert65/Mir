package Mir::Store::MongoDB;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Store::MongoDB - MongoDB driver for the Mir::Store class.

=head1 VERSION

0.0.1

=cut

our $VERSION='0.0.1';

=head1 SYNOPSIS

    use Mir::Store;

    # the create method will return back a Mir::Store::MongoDB object
    # already connected to the configured Mongo data store.
    my $store = Mir::Store->create( 
        driver => 'MongoDB',
        params => {
            "key_attr"  => "id",
            "host"      => "localhost",
            "port"      => 27017,
            "database"  => "MIR",
            "collection"=> "Foo"
    });

    # connect to Mongo, selects the Foo collection...
    $store->connect() or die "Error connecting\n";

    # delete all documents in collection..
    $store->drop();

    # find a document by its id...
    my $doc = $store->find_by_id('1');

    # insert a document in store
    my $doc_id = $store->insert({
        id => '1',
        foo => 'bar'
    });

    # count docs in collection
    my $count = $store->count();

    # update a document in store
    unless ( $store->update({
        id => '1',
        foo => 'baz'
    }) ) {
        die "Error updating document 1\n";
    }
    

=head1 DESCRIPTION

Driver class for the MongoDB data store.

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
use MongoDB;
use Log::Log4perl;
use TryCatch;

with 'Mir::R::Store';

has key_attr => (
    is       => 'rw',
    isa      => 'Str',
);

has 'host'  => (
    is      => 'rw',
    isa     => 'Str',
    default => 'localhost',
);

has 'port' => (
    is      => 'rw',
    isa     => 'Int',
    default => '27017',
);

has 'database' => (
    is      => 'rw',
    isa     => 'Str',
);

has 'client' => (
    is      => 'rw',
    isa     => 'MongoDB::MongoClient',
    init_arg  => undef,
);

has 'db_obj' => (
    is      => 'rw',
    isa     => 'MongoDB::Database',
    init_arg  => undef,
);

has 'collection' => (
    is      => 'rw',
    isa     => 'Str',
);

has 'coll' => (
    is      => 'ro',
    isa     => 'MongoDB::Collection',
    writer  => '_set_coll'
);

has 'log' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Log::Log4perl->get_logger( __PACKAGE__ ); },
);

has 'colls' => (
    is  => 'ro',
    isa => 'HashRef',
    default => sub { return {} },
);

#=============================================================

=head2 connect

=head3 INPUT

=head3 OUTPUT

A MongoDB::Collection object or undef in case of errors

=head3 DESCRIPTION

Tries to connect to the MongoDB object as configured by input
params. 
Stores the collection object in a has so subsequent calls to 
the connect subroutine for the same collection should return
the same object speeding up things.

=cut

#=============================================================
sub connect {
    my $self = shift;
    return undef unless $self->database;

    if ( exists ( $self->colls  ->{ $self->host }
                                ->{ $self->port }
                                ->{ $self->database }
                                ->{ $self->collection } ) ) {
        my $coll_obj = $self->colls->{ $self->host }
                             ->{ $self->port }
                             ->{ $self->database }
                             ->{ $self->collection };
        $self->_set_coll( $coll_obj );
        return ( $coll_obj );
    }

    try {
        $self->client( MongoDB::MongoClient->new(
            host => $self->host,
            port => $self->port,
        ) );

        $self->db_obj( $self->client->get_database( $self->database ) );
        if ( $self->collection ) {
            $self->_set_coll( $self->db_obj->get_collection( $self->collection ) );
            $self->colls->{ $self->host }
                        ->{ $self->port }
                        ->{ $self->database }
                        ->{ $self->collection } = $self->coll;
        }
    } catch  {
        $self->log->error(
            "Error getting a MongoDB database obj for database $self->{database} ".
            "and collection $self->{collection}: $@");
        return undef;
    }

    return 1;
}

sub drop {
    my $self = shift;
    $self->coll->drop();
    return 1;
}

sub find_by_id {
    my ($self, $id) = @_;
    $self->coll->find_one({ id => $id } );
}

sub insert {
    my ( $self, $doc ) = @_;
    my $key_attr = $self->key_attr;
    my $key_val = $doc->{$key_attr};

    try {
        return $self->coll->update( 
            { $key_attr => $key_val }, 
            $doc, 
            { "safe" => 1, "upsert" => 1 } );
    } catch {
        $self->log->error ("Error storing document: $_");
        return undef;
    };
}

sub update;
*update = \&insert;

sub count {
    my $self = shift;
    return $self->coll->count();
}

1;

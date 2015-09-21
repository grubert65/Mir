package Mir::R::Store;

use Moose::Role;
use namespace::autoclean;
use MongoDB;
use Log::Log4perl;
use Try::Tiny;

requires 'connect';
#requires 'find_by_id';
#requires 'insert';
#requires 'delete_all_docs';

has 'hostname' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'localhost',
);

has 'port' => (
    is      => 'rw',
    isa     => 'Int',
    default => '27017',
);

has 'db_name' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Capability',
);

has 'client' => (
    is      => 'rw',
    isa     => 'MongoDB::MongoClient',
    init_arg  => undef,
);

has 'database' => (
    is      => 'rw',
    isa     => 'MongoDB::Database',
    init_arg  => undef,
);

has 'log' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Log::Log4perl->get_logger( __PACKAGE__ ); },
);

sub connect {
    my $self = shift;
    return undef unless $self->db_name;

    try {
        $self->client( MongoDB::MongoClient->new(
            host => $self->hostname,
            port => $self->port,
        ) );
    } catch {
        $self->log->error("Error getting a MongoDB client obj: $_");
        return undef;
    };

    try {
        $self->database( $self->client->get_database( $self->db_name ) );
    } catch {
        $self->log->error("Error getting a MongoDB database obj: $_");
        return undef;
    }
    return 1;
}

1;

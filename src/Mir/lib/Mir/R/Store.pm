package Mir::R::Store;
#============================================================= -*-perl-*-

=head1 NAME

Mir::R::Store - Interface for any driver that implements a document
                store.

=head1 VERSION

0.01

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    # the driver...
    package Mir::Store::Driver;
    use Moose;
    with 'Mir::R::Store';

    ...implements interface methods...

    1;

    # get a store driver...
    my $store = Mir::Store->create( driver => 'Driver' );

    $store->connect( %connect_params )
        or die "Error connecting to store";

    # find a document by its unique id
    my $doc = $store->find_by_id( $id );

    # insert a new document into the store
    # if a key attribute has been set,
    # it first checks that no other document
    # with the same key are present in the store.
    my $new_id = $store->insert( $doc );

    # update some fields of a document
    # pointed by an id
    $store->update( $id, $fields_as_hash );
    
    # drop a document (document should still 
    # be present, only mark as deleted
    $store->drop( $id );

    # find all docs that match a filter
    my $docs = $store->find( $filter );

    # count all docs that match a filter 
    my $number_of_new_docs = $store->count({status => NEW});

    # get a new doc
    my $doc = $store->get_new_doc();


=head1 DESCRIPTION

Role all Store drivers should consume.


=head1 SUBROUTINES/METHODS


=head1 AUTHOR

Marco Masetti (grubert65 at gmail.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (grubert65 at gmail.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

#========================================================================
use Moose::Role;
use namespace::autoclean;

requires 'connect';
requires 'find_by_id';
requires 'insert';
requires 'update';
requires 'drop';
requires 'find';
requires 'count';

#=============================================================

=head2 get_new_doc

=head3 INPUT

    %options: an hash with options, as:
        sort => 1: get the oldest new document
        sort => 2: get the newest new document
        mark_as_indexing => 1: if set, the document found is
                               marked for indexing

=head3 OUTPUT

A Mir::Doc object

=head3 DESCRIPTION

Returns the first document marked as new that matches the 
passed filter. If the bool 'mark_as_indexing' is set, the 
document status is automatically upgraded to indexing.

=cut

#=============================================================
requires 'get_new_doc';

1;

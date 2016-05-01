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

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.
These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module provides.
Name the section accordingly.

In an object-oriented module, this section should begin with a sentence of the
form "An object of this class represents...", to give the reader a high-level
context to help them understand the methods that are subsequently described.


=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.


=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.


=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.


=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for
system or program resources, or due to internal limitations of Perl
(for example, many modules that use source code filters are mutually
incompatible).


=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication
whether they are likely to be fixed in an upcoming release.

Also a list of restrictions on the features the module does provide:
data types that cannot be handled, performance issues and the circumstances
in which they may arise, practical limitations on the size of data sets,
special cases that are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.
Please report problems to <Maintainer name(s)>  (<contact address>)
Patches are welcome.

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
use Moose::Role;
use namespace::autoclean;
use MongoDB;
use Log::Log4perl;
use Try::Tiny;

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

=cut

#=============================================================
requires 'get_new_doc';

1;

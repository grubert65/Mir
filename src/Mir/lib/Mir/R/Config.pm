package Mir::R::Config;
#============================================================= -*-perl-*-

=head1 NAME

Mir::R::Config - role for any Mir::Config::Client driver

=head1 SYNOPSIS

    package Mir::Config::Client::Foo;
    use Moose;
    with 'Mir::R::Config';

    # connect to the Mir::Config
    my $client = Mir::Config::Client::Foo->connect( %connection_params );

    # get the profile of a component
    #

=head1 DESCRIPTION

Defines the behaviour of any Mir::Config::Client driver.
A Mir::Config::Client interacts with a Mir::Config data store to handle the
configuration of a MIR system components.
Each component is labelled by a tag.
Each component can have a custom list of parameters.
The component profile can be modelled as a list of key/values where 'tag' is
a mandatory key.
The profile of a component can be split is different structures.
The profile tree layers are:

    tag/


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
use Moose::Role;
use namespace::autoclean;
use MongoDB;
use Log::Log4perl;
use Try::Tiny;

with 'DriverRole';

#=============================================================

=head2 connect

=head3 INPUT

An hashref with parameters specific to each specific client

=head3 OUTPUT

A Mir::Config::Client driver object.

=head3 DESCRIPTION

Connects to the proper config data store.

=cut

#=============================================================
requires 'connect';

#=============================================================

=head2 get_section

=head3 INPUT

    $section : the section (in a Mongo data stores eq to a collection

=head3 OUTPUT

An arrayref.

=head3 DESCRIPTION

Returns the complete content of a configuration section.

=cut

#=============================================================
requires 'get_section';

#=============================================================

=head2 get_id

=head3 INPUT

    $section: the section the configuration structure belongs to.
    $id: the unique configuration structure id

=head3 OUTPUT

An hashref

=head3 DESCRIPTION

Given the passed section, it looks into it for the structure
pointed to by the id.

=cut

#=============================================================
requires 'get_id';


#=============================================================

=head2 get_key

=head3 INPUT

    $section
    $key
    $value

=head3 OUTPUT

An arrayref.

=head3 DESCRIPTION

Returns all structures in section that contains the passed key/value pair.

=cut

#=============================================================
requires 'get_key';

1;

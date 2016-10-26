package Mir::Util::R::DocHandler;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::R::DocHandler - A role implemented by each Mir::Util::DocHandler
drivers

=head1 VERSION

0.02

=cut

use vars qw( $VERSION );
$VERSION='0.02';

=head1 SYNOPSIS

Refer to the L<Mir::Doc::Handler> class documentation.

=head1 DESCRIPTION

Base role to be consumed by any Mir::Util::DocHandler driver.

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
with 'Mir::R::Util',
     'Mir::R::PluginHandler'; # so each DocHandler can handle plugins

use DirHandle      ();
use File::Copy     qw( copy );
use File::stat     ();
use File::Path     qw( make_path remove_tree );
use File::Basename qw( fileparse );
use File::Type     ();
use Data::UUID;
use TryCatch;

has 'ug' => (
    is  => 'ro',
    isa => 'Data::UUID',
    default => sub { Data::UUID->new }
);

# The document path...
# along with document file name...
has 'doc_path' => ( is => 'rw', isa => 'Str' );

# only the path...
has 'path'     => ( is => 'rw', isa => 'Str' );

# only the document file name without the suffix...
has 'doc_name' => ( is => 'rw', isa => 'Str' );

# only the suffix...
has 'suffix'   => ( is => 'rw', isa => 'Str' );

# Directory for temporary
# artifacts
has 'temp_dir_root' => ( 
    is => 'rw', 
    isa => 'Str',
    default => '/tmp'
);

# if temporary folders have to 
# be deleted
has 'delete_temp_dir' => (
    is  => 'rw',
    isa => 'Bool',
    default => 1,
);

# if temporary directory
# needs to be unique.
# (otherwise it is derived from 
# document name hence being the same
# throu different calls for the same document...
has 'unique_temp_dir' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

# NOTE : do we really need this ?!?
has 'params' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { return {} },
);

#=============================================================
# number of pages of the document
# it should be valorized at document opening 
# if undefined, it means that the driver was not able 
# to detect the number of pages
#=============================================================
has 'num_pages' => (
    is      => 'ro',
    isa     => 'Maybe[Int]',
    writer  => '_set_num_pages'
);

# ---- METHODS ----
#
#=============================================================
# A method that needs to be implemented by any 
# driver. It is called internally to set the 
# number of pages.
#=============================================================
requires 'get_num_pages';

#=============================================================
# Returns text of document and the confidence on it.
# Currently implemented by each driver.
# It should take as param the page number we want to have the
# text back (undef to get all document text back)
#=============================================================
requires 'page_text';

#=============================================================

=head2 create_temp_dirs

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

To be implemented by each driver. All created folders
should be collected into the temp_dirs ArrayRef.

=cut

#=============================================================
sub create_temp_dirs {
    return 1;
}

#=============================================================
# Deletes all temp files.
#=============================================================
sub delete_temp_dirs { 
    my $self = shift;
    remove_tree( $self->temp_dir_root );
}

#=============================================================
=head2 open_doc

=head3 INPUT

$document:          path to document

=head3 OUTPUT

0/1:                fail/success

=head3 DESCRIPTION

Stores document path in object.
Creates temp_root_dir if does not exists.

=cut

#=============================================================
sub open_doc {
    my ($self, $document) = @_;

    if (not defined $document) {
        $self->log->error("No document was provided");
        return 0;
    }

    if (not stat ($document)) {
        $self->log->error("Cannot find document $document");
        return 0;
    }

    $self->{doc_path} = $document;
    my ( $filename, $path, $suffix ) = fileparse ( $document );
    $self->path( $path );

    if ( $suffix ) {
        $self->suffix( $suffix );
        $self->doc_name( $filename );
    } else {
        my ( $name, $suffix ) = $self->get_name_suffix( $filename );
        $self->suffix( $suffix );
        $self->doc_name( $name );
    }

    if ( $self->unique_temp_dir ) {
        my $uuid = $self->ug->create();
        $self->{temp_dir_root} = $self->{temp_dir_root}.'/'.
                                 $self->ug->to_string( $uuid );
    } else {
        $self->{doc_name} =~ s/\W//g;
        $self->{temp_dir_root} = $self->{temp_dir_root}.'/'.
            $self->{doc_name};
    }

    make_path ( $self->{temp_dir_root} ) 
        unless ( -d $self->{temp_dir_root} );

    $self->_set_num_pages( $self->get_num_pages() );
    $self->create_temp_dirs();

    return 1; 
}

1; # End of Mir::Util::DocHandler

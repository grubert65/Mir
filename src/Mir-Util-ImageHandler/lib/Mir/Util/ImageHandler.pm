package Mir::Util::ImageHandler;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::ImageHandler - A class to handle images

=head1 VERSION

0.01

=cut

# HISTORY
# 0.02 | 19.10.16 | Now plugins can be configured for image preprocessing
our $VERSION='0.02';

=head1 SYNOPSIS

    use Mir::Util::ImageHandler;

    my $o = Mir::Util::ImageHandler->new();

    # Extracts all images from a pdf file
    # and store them in a given folder starting
    # with a given root name...
    # Returns the array ref of all extracted images.
    my $image_files = $o->pdfimages(
        pdf_file    => './a-pdf-file.pdf',
        page_num    => 1,
        out_root    => './images/foo', # all images will get stored
                                        # here with foo prefix...
        params      => '-png', # refer to the pdfimages cmd for 
                               # a complete list of parameters 
    );

    my $ih = Mir::Util::ImageHandler->new(
        plugins => {},  # See  Mir::R::PluginHandler for details
    );

    # open a list of image files.
    # this can be called several times, all images get stacked in
    # the same object.
    # all subsequent methods ending with "_all" will apply to
    # all stacked images, otherwise they will apply to last
    # image file opened...
    $ih->open( qw( 'an-image-filepath' ) ) or die "Error opening image";

    # rotates the image
    # at the end the $image obj will point to the new image...
    my $rotated = $ih->rotate('45');

    # rotate again of other 45 degrees...
    $rotated = $ih->rotate('45');

    # Write the rotated image to a new file...
    my $rotated_file = $ih->write();

    # delete all images...
    $ih->delete_all();


=head1 DESCRIPTION

This class can be used to perform some simple operations on images.
It lets you extract and store all images found in a pdf page.
It lets you rotate an image and store it as a new image.
It lets you perform other custom image processing operations on images.
Finally it lets you delete all created images...


=head1 AUTHOR

Marco Masetti (marco.masetti @ softeco.it )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SUBROUTINES/METHODS

=cut

#========================================================================
use Moose;
with 'Mir::R::PluginHandler';

use File::Path      qw(make_path);
use File::Basename  qw(dirname basename fileparse);
use DirHandle;
use Image::Magick;
use Log::Log4perl;
use Data::UUID;
use Data::Dumper    qw(Dumper);
use File::Which     qw(which);

has 'image_files' => (
    is      => 'rw',
    isa     => 'ArrayRef',
);

has 'im' => (
    is      => 'ro',
    isa     => 'Image::Magick',
    default => sub { 
        my $o = Image::Magick->new();
        $o->Set( display => '0:0' );
        return $o;
    },
);

has 'log' => (
    is  => 'ro',
    isa => 'Log::Log4perl::Logger',
    default => sub { Log::Log4perl->get_logger( __PACKAGE__ ); },
);

# image pre processing plugins configuration
has 'plugins' => ( 
    is  => 'rw', 
    isa => 'HashRef',
    trigger => \&_register_plugins
);

sub _register_plugins {
    my ( $self, $plugins ) = @_;
    $self->log->debug("Registering plugins:");
    $self->log->debug( sub { Dumper ( $plugins ) } );
    $self->register_plugins( $plugins );
}

#=============================================================

=head2 open - Opens an image file adding it to the stack

=head3 INPUT

An array of images to open...

=head3 OUTPUT

=head3 DESCRIPTION

Checks image exists and opens it, setting the
current image format...
Returns the total number of images opened

=cut

#=============================================================
sub open {
    my ( $self, @file ) = @_;

    foreach ( @file ) {
        unless ( -f $_ ) {
            $self->log->error("Image file $_ not loadable!");
            die "Image file $_ not loadable!\n";
        }
    }

    my $ret = $self->im->Read( @file );
    if ( "$ret" ) {
        $self->log->error("Error reading image: ".join(' ', @file));
        die("Error reading image: ".join(' ', @file));
    }
    push @{$self->{image_files}}, @file;
}

#=============================================================

=head2 delete_all

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

=cut

#=============================================================
sub delete_all {
    my $self = shift;
    @{$self->im} = (); # NOTE: this deletes all images...
    unlink @{$self->{image_files}} if ( defined $self->{image_files} );
}

#=============================================================

=head2 pdfimages

=head3 INPUT

An hash with the following keys:
    pdf_file    :   Path to the pdf file
    page_num    :   The page number (starting from 1)
    out_root    :   The output folder
    params      :   A string of other params to be passed to
                    the pdfimages command. 
                    Refer to the pdfimages command manpage
                    By default a -tiff parameter is passed
                    this force all extracted images to be 
                    stored as tiff.

=head3 OUTPUT

An ArrayRef

=head3 DESCRIPTION

Workflow:
- checks input params
- if dirname of out root doesn't exists creates it otherwise
deletes any file with the out root
- prepare cmd and launchs it
- look for any create file with our root
- then computes a simple histogram of each image and get rid 
of images that are or completely white or completely black...
- returns (a ref to) the list of created file paths

TODO most of the workflow still to be done...

=cut

#=============================================================
sub pdfimages {
    my ( $self, %params ) = @_;

    my $cmd = which('pdfimages');
    unless ($cmd) {
        $self->log->error("No pdfimages cmd found");
        return undef;
    }

    foreach ( qw( pdf_file page_num out_root ) ) {
        return undef unless exists ( $params{$_} );
    }

    $params{params} ||= '-tiff';

    my @image_files = ();
    my $file_root   = basename ( $params{out_root} );
    my $out_dir     = dirname( $params{out_root} );
    make_path( $out_dir ) unless ( -d $out_dir );

    # delete all files starting with file_root...
    my $d = DirHandle->new( $out_dir );
    my @files_to_delete = grep { -f            }
                          map  { "$out_dir/$_" }
                          grep { /^$file_root/ }
                          $d->read();
    $d->close();
    unlink @files_to_delete;

    my @args = ( $cmd, 
        "-f $params{page_num}", 
        "-l $params{page_num}", 
        $params{params},
        "\""."$params{pdf_file}"."\"",
        "$params{out_root}",
    );

    my $c = join( ' ', @args );
    $self->log->debug("pdfimages cmd:\n$c");
    system ( $c ) == 0 
        or return undef;

    my $d2 = DirHandle->new( $out_dir );
    @image_files = 
        grep { -f             }
        map  { "$out_dir/$_"  }
        grep { /^$file_root/  }
        $d2->read();
    $d2->close();

    my @processed_image_files;
    $self->call_registered_plugins({
        hook            => 'image_pre_processing',
        input_params    => \@image_files,
        output_params   => \@processed_image_files
    });

    # just checks that images contains some 
    # information...
    for (my $i=0;$i<$#image_files;$i++) {
        $self->im->Read( $image_files[$i] );
        my @hist = $self->im->Histogram();
        my ($r, $g, $b, $a, $count) = splice @hist, 0, 5;
        if ((( $r + $g + $b ) > (65530 + 65530 + 65530 )) ||
            (( $r + $g + $b ) < 30 )) {
            $self->log->warn("Image $image_files[$i] too dark or too bright, rejected...");
            unlink $image_files[$i];
            splice @image_files, $i, 1;
        } 
    }
    @{$self->im} = ();
    return \@image_files;
}

#=============================================================

=head2 rotate

=head3 INPUT

    degrees: number of degrees to rotate the image.
             Refer to convert tool documentation.

=head3 OUTPUT

=head3 DESCRIPTION

=cut

#=============================================================
sub rotate {
    my ( $self, $degrees ) = @_;

    $self->im->[-1]->Rotate( $degrees );
    return 1;
}

#=============================================================

=head2 write

=head3 INPUT

A file path. If not passed, a unique file path will be created

=head3 OUTPUT

The filepath of the new image

=head3 DESCRIPTION

Tries to write the image to a passed filepath or generates
a unique filepath to use.
Returns the new filename.

=cut

#=============================================================
sub write {
    my ( $self, $filepath ) = @_;

    unless ( $filepath ) {
        my $filename = $self->im->[-1]->Get( 'filename' );
        my ( $basename, $path, $suffix ) = fileparse( $filename );
        $suffix ||= (split(/\./, $basename))[-1];
#         unless ( $suffix ) {
#             if ( $basename =~ m|\.(\w+)$| ) {
#                 $suffix = $1;
#             }
#         }
        my $ug = Data::UUID->new; 
        my $uuid = $ug->create();
        $filepath = $path . $ug->to_string( $uuid ) . "\.$suffix";
    }

    my $num = $self->im->[-1]->Write( $filepath );
    $self->log->debug("Image written into $filepath");
    push @{$self->{image_files}}, $filepath;
    return $filepath;
}

no Moose;
__PACKAGE__->meta->make_immutable;

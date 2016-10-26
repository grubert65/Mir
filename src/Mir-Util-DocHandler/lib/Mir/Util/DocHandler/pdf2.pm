package Mir::Util::DocHandler::pdf2;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::pdf2 - Driver class to handle PDF
documents. This driver actually converts pages into images to 
overcome issues extracting text via libraries.

To make it the default driver simply hack the 
Mir::Util::DEL::Indexer::_FileType method to return 'pdf2' 
for pdf files.

=head2 SYNOPSIS

    use Mir::Util::DocHandler;

    my $doc = Mir::Util::DocHandler->create( driver => 'pdf2');

    # open a pdf doc...
    $doc->open_doc( $file_path );

    # get number of pages...
    my $page_num = $doc->pages();

    # extract a page as single pdf file...
    # returns the abs path to the pdf file
    my $pdf_page_path = $doc->extractPage( $page_num);

    # convert a pdf file to an image
    $doc->convertToImage( $pdf_page_path, $img_file )
        or die "Error converting pdf page";

    # get text for a given page...
    my ( $text, $confidence ) = $doc->page_text( $page_num );

    # or extract all pages at once...
    my $array = $doc->extractAllAndConvert();

=head2 DESCRIPTION

This driver handles pdf documents, providing methods for getting
the number of pages and extracting text from a single page.

=head2 EXPORT

None by default.

=head2 SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc <module>

=head2 SEE ALSO

=head2 AUTHOR

Andrea Poggi <andrea.poggi at softeco dot it>

=head2 COPYRIGHT and LICENSE

Copyright (C) 2009 Andrea Poggi.  All Rights Reserved.
Copyright (C) 2009 Softeco Sismat SpA.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

=head2 FUNCTIONS

=cut

#========================================================================
use Moose;
use namespace::autoclean;
with 'Mir::Util::R::DocHandler', 
     'Mir::Util::R::OCR',
     'Mir::Util::R::PDF';

use File::Path      qw( make_path rmtree );
use File::Basename  qw( basename dirname fileparse);
use File::Remove    qw( remove );
use File::Copy      qw( copy );
use Image::Size     qw( imgsize );
use Imager;
use PDF::Extract;
use DirHandle;
use Data::UUID;
use TryCatch;

use vars qw( $VERSION );

# 0.01 : first stable release
# 0.02 : added crop method
# 0.03 : ported under Mir
# 0.04 : now uses $ENV{CACHE_DIR} (defaults to /tmp) as
#        basedir. This prevents errors in case we don't
#        have priviledges on the pdf base fodler...
# 0.05 : bug fixing...
# 0.06 : rewriting some stuff...
$VERSION = '0.06';

has 'uid' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 
        my $ug = Data::UUID->new();
        my $uuid = $ug->create();
        return $ug->to_string( $uuid );
    }
);

has 'pdfex' => (
    is      => 'ro',
    isa     => 'PDF::Extract',
    default => sub { PDF::Extract->new() },
);

# the pdf document and where everything get stored...
has 'pdf'           => ( is => 'rw', isa => 'Str' );
has 'page_num'      => ( is => 'rw', isa => 'Int' );
has 'basedir'       => ( is => 'rw', isa => 'Str' );
has 'filename'      => ( is => 'rw', isa => 'Str' );
has 'suffix'        => ( is => 'rw', isa => 'Str' );
has 'pdf_pages_dir' => ( is => 'rw', isa => 'Str' );
has 'pdf_images_dir'=> ( is => 'rw', isa => 'Str' );
has 'pdf_text_dir'  => ( is => 'rw', isa => 'Str' );

$ENV{CACHE_DIR} //= '/tmp';

#=============================================================

=head2 create_temp_dirs

=head3 INPUT

=head3 OUTPUT

1

=head3 DESCRIPTION

Create temporary directories:
    - pages:    where single page pdfs get stored
    - images:   where single page images get stored
    - text:     where document text files get stored

=cut

#=============================================================
sub create_temp_dirs {
    my $self = shift;

    $self->pdf_pages_dir ("$self->{temp_dir_root}/pages");
    $self->pdf_images_dir("$self->{temp_dir_root}/images");
    $self->pdf_text_dir  ("$self->{temp_dir_root}/text");

    $self->pdfex->setPDFExtractVariables( 
        PDFDoc   => $self->{doc_path},
        PDFCache => $self->pdf_pages_dir 
    );

    return 1 if ( -d $self->pdf_pages_dir && 
                  -d $self->pdf_images_dir &&
                  -d $self->pdf_text_dir
    );

    foreach ( qw( pdf_pages_dir pdf_images_dir pdf_text_dir ) ) {
        make_path ($self->{$_}) if ( ! -d $self->{$_} );
    }
    
    return 1; 
}

#=============================================================

=head2 extractAllAndConvert

=head3 INPUT

=head3 OUTPUT

[] An arrayref of hashes with keys:
    pdf: the pdf file path
    img: the image file path

=head3 DESCRIPTION

Splits the doc into single pdf pages and convert each into 
an image.

=cut

#=============================================================
sub extractAllAndConvert {
    my $self = shift;

    my @pages;
    if ( $self->num_pages ) {
        foreach( my $page_num=1;$page_num<=$self->num_pages;$page_num++){
            # extract each page as single pdf
            my $pdf_file = $self->extractPage ($page_num)
                or next;
            
            my $img_file = $self->_get_image_file( $page_num );

            # convert each pdf page in image
            $self->convertToImage($pdf_file, $img_file) or next;

            push @pages, { pdf => $pdf_file, img => $img_file };
        }
    }
    return \@pages;
}


sub _get_image_file {
    my ( $self, $page ) = @_;
    return $self->pdf_images_dir.'/'.$self->{doc_name}.'-'.$page.'.jpg';
}

#=============================================================

=head2 page_text

=head3 INPUT

    $page:     page number
    $lang:     the supposed text language

=head3 OUTPUT

    $text:        Text of page if successful, undef if not
    $confidence:  Estimated accuracy of extracted text

=head3 DESCRIPTION

Returns text of desired page of document page.
The page is converted in image and text is extracted using
OCR.
Returns ( undef, 0 ) in case of errors.

=cut

#=============================================================
sub page_text {
    my ($self, $page, $lang) = @_;

    $DB::single=1;
    my $img_file = $self->_get_image_file( $page );
    $self->log->debug("Going to extract text from image: $img_file");
    try {
        unless ( -e "$img_file" ) {
            $self->log->debug("Image $img_file not existent, going to extract page and convert...");
            my $pdf_page = ( $self->page_num > 1 ) ? $self->extractPage( $page ) : $self->pdf;
            die ("PDF page not found") unless ( -f $pdf_page );
            $self->convertToImage( $pdf_page, $img_file ) or die "Error converting image";
        }
        return $self->get_ocr( "$img_file", "$self->{pdf_text_dir}/$self->{filename}-$page", $lang );
    } catch {
        $self->log->error( $@ );
        return ( undef, 0 );
    }
}

#=============================================================

=head2 extractPage

=head3 INPUT

    $page_num: the page number to extract 

=head3 OUTPUT

$outfile/undef in case of error

=head3 DESCRIPTION

Extract a single page from passed file and stores it as
pdf with file name <base filename>-<page_num>.pdf

=cut

#=============================================================
sub extractPage {
    my ( $self, $page_num ) = @_;

    my $pdf_page=$self->{pdf_pages_dir}.'/'.$self->{filename}.$page_num.'.pdf';
    my $pdf_page_name = $self->{filename}.$page_num;
    return $pdf_page if (-e $pdf_page );
    try {
        # apparently, if several objects are instantiated, 
        # you have to specify to PDF::Extract all parameters
        # each time..
        $self->pdfex->setPDFExtractVariables( 
            PDFDoc   => $self->pdf,
            PDFCache => $self->pdf_pages_dir,
            PDFSaveAs => "$pdf_page_name" 
        );

        $DB::single=1;
        my $ret = $self->pdfex->savePDFExtract( PDFPages=>$page_num );
        if ( $ret == 0 ) {
            $self->log->error( $self->pdfex->getVars("PDFError") );
            return undef;
        }
        return $pdf_page;
    } catch {
        $self->log->error("Error extracting page $page_num: $@");
        return undef;
    }
}

#=============================================================

=head2 convertToImage

=head3 INPUT

    $pdf_file: path to the pdf file to be converted
    $img_file: path of the image

=head3 OUTPUT

1/undef in case of errors.

=head3 DESCRIPTION

Converts pdf file to jpg image...

=cut

#=============================================================
sub convertToImage {
    my ( $self, $pdf_file, $img_file ) = @_;

    return undef unless -e $pdf_file;
    return 1 if ( -e $img_file );

    # check that the convert tool is installed
    my $ret = system("which convert");
    if ( $ret != 0 ) {
        $self->log->error("ERROR: convert seems not present on this platform");
        return undef;
    }

    my $cmd = "convert -density 300 -quality 100 \"$pdf_file\" \"$img_file\"";
    $ret = system( $cmd );
    if( $ret != 0 ) {
        $self->log->error("ERROR executing cmd: $cmd");
        return undef;
    }

    return -e $img_file; #check at least that file exists...
}


#=============================================================

=head2 crop

=head3 INPUT

    $img_file: the image to crop
    $crop_params: an hashref with key left, right, top, bottom
    marking the area of the image to crop to.

=head3 OUTPUT

the image filename /undef in case of errors

=head3 DESCRIPTION

Crop the image, rewrite the image file

=cut

#=============================================================
sub crop {
    my ( $self, $img_file, $crop_params ) = @_;

    return undef unless ( -e $img_file );
    my $img = Imager->new();
    $img->read( file => $img_file );
    if ( $@ ) {
        $self->log->error("Error reading image $img_file, cropping not possible: $@");
        return undef;
    }
    
    my $cropped = $img->crop( %$crop_params );
    if ( $@ ) {
        $self->log->error("Error cropping image $img_file: $@");
        return undef;
    }

# TODO why  doesn't store cropped image in a new file ?
#    my ( $dirname, $basename ) = (dirname ($img_file), basename ($img_file));
#    my ( $filename, $suffix ) = split(/\./, $basename);
#    my $cropped_file = $dirname.'/'.$filename.'-cropped'.'.'.$suffix;

    $cropped->write( file => $img_file );
    if ( $@ ) {
        $self->log->error("Error writing image $img_file, cropping not possible: $@");
        return undef;
    }

    return $img_file;
}

#=============================================================

=head2 delete_temp_files

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

Deletes the basedir folder

=cut

#=============================================================
sub delete_temp_files {
    my $self = shift;
    $DB::single=1;
    rmtree($self->basedir);
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

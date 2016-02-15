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
    # returns the abs path to the image file
    my $image_file_path = $doc->convertToImage( $pdf_page_path );

    # get text for a given page...
    my ( $text, $confidence ) = $doc->page_text( $page_num, $temp_dir );

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
with 'Mir::Util::R::DocHandler';

use namespace::autoclean;
use Image::OCR::Tesseract       qw( get_ocr );
use File::Path                  qw( rmtree );
use File::Basename              qw( basename dirname );
use Image::Size                 qw( imgsize );
use Imager;
use PDF::Extract;
use DirHandle;

use vars qw( $VERSION );

# 0.01 : first stable release
# 0.02 : added crop method
# 0.03 : ported under Mir
$VERSION = '0.03';

#binmode(STDOUT, ':utf8');

# tesseract confidence on extraction
has 'confidence' => ( 
    is      => 'rw', 
    isa     => 'Int',
    lazy    => 1,
    default => sub { return 100; }
);

# the pdf document and where everything get stored...
has 'pdf'           => ( is => 'rw', isa => 'Str' );
has 'page_num'      => ( is => 'rw', isa => 'Int' );
has 'pdf_pages_dir' => ( is => 'rw', isa => 'Str' );
has 'pdf_images_dir'=> ( is => 'rw', isa => 'Str' );
has 'pdf_text_dir'  => ( is => 'rw', isa => 'Str' );

$ENV{SM2_TEMP_DIR} //= '/tmp';

#=============================================================

=head2 open_doc

=head3 INPUT

    $pdf:          path to pdf doc

=head3 OUTPUT

    0/1:                fail/success

=head3 DESCRIPTION

Opens provided document and stores its path in object.
Creates these subfolders:
    - pages:    where single page pdfs get stored
    - images:   where single page images get stored

TODO : should return page number...

=cut

#=============================================================
sub open_doc {
    my ($self, $pdf) = @_;

    return undef unless $pdf;
    $self->pdf( $pdf ) if ( $pdf );

    if (not stat ($self->pdf)) {
        $self->log->error("Cannot find document $self->{pdf}");
        return 0;
    }

    my $basedir = dirname( $self->pdf );
    $self->pdf_pages_dir("$basedir/pages");
    $self->pdf_images_dir("$basedir/images");
    $self->pdf_text_dir("$basedir/text");

    $self->{filename} =  basename ( $self->pdf );
    ($self->{basename}, $self->{suffix}) = split(/\./, $self->{filename});

    my $infos;
    my $cmd = "pdfinfo \"$pdf\" > $basedir/pdf_info_file.txt 2>&1";
    my $ret = system($cmd);
    if ($ret == 0) {
        # Get infos and delete temp dir...
        open (PDF_INFO, "<:encoding(utf8)", "$basedir/pdf_info_file.txt");
        read (PDF_INFO, $infos, (stat(PDF_INFO))[7]);
        close (PDF_INFO);
        
        # If everything was OK, get document infos
        if ($infos =~ /pages\:.*?(\d{1,})/i) {
            $self->page_num( $1 );
        } else {
            $self->log->error("Cannot get document $pdf infos") if $self->log;
            return 0;
        }
    }

    return 1 if ( -d $self->pdf_pages_dir && -d $self->pdf_images_dir );

    foreach ( qw( pdf_pages_dir pdf_images_dir ) ) {
        mkdir ($self->{$_}) if ( ! -d $self->{$_} );
    }
    
    return 1; 
}

sub pages {
    my $self = shift;
    return $self->page_num;
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
    if ( $self->page_num ) {
        foreach( my $page_num=1;$page_num<=$self->page_num;$page_num++){
            # extract each page as single pdf
            my $pdf_file = $self->extractPage ($page_num)
                or return undef;

            # convert each pdf page in image
            my $img_file = $self->convertToImage($pdf_file) or return undef;

            push @pages, { pdf => $pdf_file, img => $img_file };
        }
    }
    return \@pages;
}

#=============================================================

=head2 page_text

=head3 INPUT

    $page:     page number
    $temp_dir: temp dir where text is stored (not mandatory)

=head3 OUTPUT

    $text:        Text of page if successful, undef if not
    $confidence:  Estimated accuracy of extracted text

=head3 DESCRIPTION

Returns text of desired page of document page.
The page is converted in image and text is extracted using
OCR.

=cut

#=============================================================
sub page_text {
    my ($self, $page, $temp_dir) = @_;

    my $text = "";
    my $confidence = $self->confidence;

    my @path = split(/\//, $self->pdf);
    my ($filename, $suffix) = split(/\./, $path[-1]);
    my $img = $self->pdf_images_dir.'/'.$filename.$page.'.jpg';
    $self->log->debug("Going to extract text from image: $img");
    if (! -e $img ) {
        $self->log->debug("Image $img not existent, going to extract page and convert...");
        my $page = $self->extractPage( $page );
        $img = $self->convertToImage( $page );
        return undef unless ( $img && -e $img );
    }

    $text = get_ocr( $img, $ENV{SM2_TEMP_DIR}, 'ita' );
    if ( $text =~ /average_doc_confidence:(\d{1,3})/ ) {
        $confidence = $1;
        $text =~ s/average_doc_confidence:(\d{1,3})//g;
    }

    $self->_delete_temp_files( $ENV{SM2_TEMP_DIR} );

    $self->log->debug("Confidence: $confidence");
    $self->log->debug("Text      :\n\n$text");
    return ($text, $confidence);
}

#=============================================================

=head2 _delete_temp_files

=head3 INPUT

    $temp_dir: the temporary folder

=head3 OUTPUT

=head3 DESCRIPTION

Deletes all .jpg, .tif and .txt from the temp folder.

=cut

#=============================================================
sub _delete_temp_files {
    my ( $self, $temp_dir ) = @_;

    my @files=plainfiles($temp_dir, 'jpg');
    foreach ( @files ) {
        unlink $_;
    }
}

sub plainfiles {
    my ($dir, $pattern) = @_;
    my $dh = DirHandle->new($dir)   or die "can't opendir $dir: $!";

    return sort { -M $a cmp -M $b }  # sort pathnames by last mod date...
           grep { /(\w+)\.$pattern/ }
           grep {    -f       }      # choose only "plain" files
           map  { "$dir/$_"   }      # create full paths
           grep { !/^\./      }      # (eventually) filter out dot files
           $dh->read();              # read all entries
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

    my $pdf_page=$self->{pdf_pages_dir}.'/'.$self->{basename}.$page_num.'.'.$self->{suffix};
    return $pdf_page if (-e $pdf_page );
    my $pdf=new PDF::Extract( PDFDoc=> $self->pdf );
    $pdf->setVars( PDFCache => $self->{pdf_pages_dir} );
    my $ret = $pdf->savePDFExtract( PDFPages=>$page_num );
    if ( $ret == 0 ) {
        $self->log->error( $pdf->getVars("PDFError") );
        return undef;
    }

    return $pdf_page;
}

#=============================================================

=head2 convertToImage

=head3 INPUT

    $pdf_file: path to the pdf file to be converted

=head3 OUTPUT

$outfile/undef in case of errors.

=head3 DESCRIPTION

Converts pdf file to jpg image...

=cut

#=============================================================
sub convertToImage {
    my ( $self, $pdf_file ) = @_;

    return undef unless -e $pdf_file;

    # check that the convert tool is installed
    my $ret = system("which convert");
    if ( $ret != 0 ) {
        $self->log->error("ERROR: convert seems not present on this platform");
        return undef;
    }

    my @path = split(/\//, $pdf_file);
    my ($filename, $suffix) = split(/\./, $path[-1]);

    my $img_file = $self->pdf_images_dir.'/'.$filename.'.jpg';
    return $img_file if ( -e $img_file );

    my $cmd = "convert -density 300 -quality 100 \"$pdf_file\" \"$img_file\"";
    $ret = system( $cmd );
    if( $ret != 0 ) {
        $self->log->error("ERROR executing cmd: $cmd");
        return undef;
    }
    return undef unless -e $img_file; #check at least that file exists...
    return $img_file;
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

no Moose;
__PACKAGE__->meta->make_immutable;

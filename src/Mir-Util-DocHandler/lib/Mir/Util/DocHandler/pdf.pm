package Mir::Util::DocHandler::pdf;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::pdf - Driver class to handle PDF
documents

=head2 SYNOPSIS

    use Mir::Util::DocHandler;

    my $doc = Mir::Util::DocHandler->create( driver => 'pdf' );

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

Copyright (C) 2015 Andrea Poggi.  All Rights Reserved.
Copyright (C) 2015 Softeco Sismat SpA.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

=head2 FUNCTIONS

=cut

#========================================================================
use Moose;
with 'Mir::Util::R::DocHandler';

use PDF::API2                   ();
use CAM::PDF                    ();
use Image::OCR::Tesseract       qw( get_ocr );
use File::Path                  qw( rmtree );
use Time::HiRes                 qw( gettimeofday );
use Image::Size                 qw( imgsize );
use Imager                      ();
use Encode                      qw( encode decode );
use File::Basename              qw( dirname basename );

use constant DPI        => 72; # Consider monitor DPIs
use constant AREA       => 1260; # A4 row area (1260 square millimeters)
use constant PDF_API2   => 100; 
use constant CAM_PDF    => 101; 
use constant CAM_PDF_CONF    => 95; 
use constant PDF_INFO_CONF   => 90; 
use constant MAX_PAGES  => 100;

use vars qw( $VERSION  );

# 0.01 : first stable release

$VERSION = '0.01';

#=============================================================

=head2 open_doc

=head3 INPUT

$document:          path to document

=head3 OUTPUT

0/1:                fail/success

=head3 DESCRIPTION

Opens provided document and stores its path in object

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
    
    my $pdf_doc;

    # Create temp dir...
    my $temp_dir .= $self->{'TEMP_DIR'}."/"._generateUUID();
    rmtree ($temp_dir) if stat ($temp_dir);
    mkdir ($temp_dir);
    my $infos;
    my $cmd = "pdfinfo \"$document\" > $temp_dir/pdf_info_file.txt 2>&1";
    my $ret = system($cmd);
    if ($ret == 0) {
        # Get infos and delete temp dir...
        open (PDF_INFO, "<:encoding(utf8)", "$temp_dir/pdf_info_file.txt");
        read (PDF_INFO, $infos, (stat(PDF_INFO))[7]);
        close (PDF_INFO);
        rmtree ($temp_dir) if stat ($temp_dir);
        
        # If everything was OK, get document infos
        if ($infos =~ /pages\:.*?(\d{1,})/i) {
            $self->{'pages'} = $1;
        } else {
            $self->log->error("Cannot get document $document infos") if $self->log;
            return 0;
        }
    } else {
        # Sorry, no way to handle this document...
        $self->log->error("Cannot open document $document with any tool, giving up") if $self->log;
        return 0;
    }
    
    $self->{'DOC_PATH'} = $document;

    return 1; 
}

#=============================================================

=head2 pages

=head3 INPUT

=head3 OUTPUT

Number of pages if successful, undef if not

=head3 DESCRIPTION

Returns number of pages of document

=cut

#=============================================================
sub pages
{
    my ($self) = shift;

    my $doc = $self->{'DOC_PATH'};
    if (not defined $doc) {
        $self->log->error("No document was ever opened");
        return undef;
    }

    my $pages = $self->{'pages'};

    return $pages; 
}

#=============================================================

=head2 page_text

=head3 INPUT

$page:                  page number
$temp_dir:              temp dir where text is stored

=head3 OUTPUT

$text:                  Text of page if successful, undef if not
$confidence:            Estimated accuracy of extracted text

=head3 DESCRIPTION

Returns text of desired page of document

=cut

#=============================================================
sub page_text
{
    my ($self, $page, $temp_dir) = @_;

    my $doc = $self->{'DOC_PATH'};
    if (not defined $doc) {
        $self->log->error("No document was ever opened");
        return undef;
    }

    my $ocr_threshold = $self->{'OCR_THRESHOLD'};
    my $text = "";
    my $confidence = $self->{'CONFIDENCE'};
    $temp_dir = $self->{TEMP_DIR} unless ( $temp_dir );
    $temp_dir .= "/"._generateUUID();
    rmtree ($temp_dir) if stat ($temp_dir);
    mkdir ($temp_dir);

    # Get text using pdftotext first...
    # pdftotext default encoding for output text is Latin1, we force to encode in utf8
    my $cmd = "pdftotext -nopgbrk -enc UTF-8 -f $page -l $page \"$doc\" $temp_dir/page.txt > /dev/null 2>&1";
    my $ret = system($cmd);

    if ($ret == 0) {
        open (SINGLE_PAGE, "<:encoding(utf8)", "$temp_dir/page.txt");
        read (SINGLE_PAGE, $text, (stat(SINGLE_PAGE))[7]);
        close (SINGLE_PAGE);

        if ( $text ) {
            # removing weird code points...
            # (all Unicode first 0x1f control chars...
            # they may corrupt the CMS portal...
            # we actually replace them with a space to avoid words collision...
            my $hex;
            for (my $i=0x00;$i<=0x1f;$i++) {
                $hex = sprintf("%X", $i);
                $text =~ s/\x{$hex}/\x{20}/g;
            }
    
            # extracting text from PDF can result in some non printable chars
            # the following should be connected with pdf 'bookmarks'
            # this again can corrupt the CMS representation...
            $text =~ s/\cH/ /g;
        } else {
            $confidence = 0;
        }
        unlink "$temp_dir/page.txt";
    } else {
        $self->log->error("Unable to read page $page from document $doc");
        return (undef, 0);
    }

    # ...then look for images to process with OCR (only if we don't have too much pages to process)
    if ( $self->{pages} < MAX_PAGES ) {
        $cmd = "pdfimages -f $page -l $page \"$doc\" $temp_dir/images";
        $ret = system($cmd);
        
        if ($ret == 0) {
            opendir (DIR, "$temp_dir");
            my @dir_content = readdir DIR;
            my @pagefiles = map { "$temp_dir/$_" } sort grep { /images.+\.p.m$/i } @dir_content;
            closedir(DIR);
             # for each page, get text and retrieve confidence
             my $total_images = (scalar @pagefiles);
             foreach my $page_image (@pagefiles) {
                my $ocr_OK = 1;
                my $ocr_text;
                my @rot_angles = (90, 270);
                # If size is too small, skip it
                if (_checkSize($page_image, DPI, AREA)) {
                    # TODO should we force text encoding here as well ?!?
                    $ocr_text = get_ocr($page_image, undef, 'ita');
    #                $ocr_text = decode( 'iso-8859-1', $ocr_text );
    #                $ocr_text = encode( 'utf8', $ocr_text);
                    if ($ocr_text =~ /average_doc_confidence\:(\d{1,})/g) {
                        # If image confidence is below threshold, try to rotate
                        # it, in case it was badly oriented
                        if (defined $ocr_threshold && $1 <= $ocr_threshold) {
                            my $max_conf = 0;
                            my $imager;
                            my $rotated_ocr_text;
                            foreach my $rot_angle (@rot_angles) {
                                $imager = Imager->new(file=>$page_image) if not defined $imager;
                                my $rotated = $imager->rotate(degrees => $rot_angle);
                                $rotated->write(file => $page_image);
                                $rotated_ocr_text = get_ocr($page_image, undef, 'ita');
    #                            $rotated_ocr_text = decode( 'iso-8859-1', $rotated_ocr_text );
    #                            $rotated_ocr_text = encode( 'utf8', $rotated_ocr_text);
                                if ($rotated_ocr_text =~ /average_doc_confidence\:(\d{1,})/g) {
                                    if (($1 > $max_conf) && ($1 > $ocr_threshold)) {
                                        $max_conf = $1;
                                        $ocr_text = $rotated_ocr_text;
                                    }
                                }
                            }
                            # If its confidence is still below threshold, discard it;
                            # it's probably garbage and it would lower the total
                            # page confidence
                            if ($max_conf > 0) {
                                $confidence += $max_conf;
                                $ocr_text =~s/average_doc_confidence\:\d{1,}//g;
                            } else {
                                $total_images--;
                                $ocr_OK = 0;
                            }
                        } else {
                            $confidence += $1;
                            $ocr_text =~s/average_doc_confidence\:\d{1,}//g;
                        }
                    }
                } else {
                    $total_images--;
                    $ocr_OK = 0;
                }
                $text .= "\n".$ocr_text if $ocr_OK;
            }
            if ($total_images > 0) {
                $confidence /= $total_images + 1;
            }
        }
    }

    rmtree($temp_dir) if stat ($temp_dir);
    return ($text, $confidence);
}

#=============================================================

=head1 _generateUUID

=head2 INPUT

=head2 OUTPUT

=head2 DESCRIPTION

    Genereates a unique identifier based on current time

=cut

#=============================================================
sub _generateUUID
{
    my ($seconds, $microseconds) = gettimeofday;
    return "$seconds".'_'."$microseconds";
}

#=============================================================

=head1 _checkSize

=head2 INPUT
    $filepath:          path to image
    $dpi:               dpi of image
    $area:              min area of the image

=head2 OUTPUT
    $ret:               1 if area of image is bigger than
                        $area, 0 otherwise

=head2 DESCRIPTION

    Checks area of image against providede area

=cut

#=============================================================
sub _checkSize
{
    my ($filepath, $dpi, $area) = @_;
    
    my ($x, $y) = imgsize($filepath);
    if ( (defined $x) && (defined $y) ) {
        my $image_area = ($x/$dpi)*($y/$dpi)*(25.4);
        if ($image_area >= $area) {
            return 1;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

1;

__END__
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
 
THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
 
You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.


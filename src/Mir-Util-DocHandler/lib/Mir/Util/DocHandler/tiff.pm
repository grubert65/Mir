package Mir::Util::DocHandler::tiff;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::tiff - Driver class to handle tiff
images

=head2 SYNOPSIS

    use Mir::Util::DocHandler::tiff;

    my $doc = Mir::Util::DocHandler::tiff->new();

=head2 DESCRIPTION

This driver handles tiff images, providing methods for 
extracting text from them.

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

use Image::OCR::Tesseract       qw( get_ocr );
use File::Path                  qw( rmtree );
use Time::HiRes                 qw( gettimeofday );
use Image::Size                 qw( imgsize );
use Imager                      ();
use File::Basename              qw( basename );
use File::Copy                  qw( copy );
use File::Type                  ();

use constant DPI        => 72; # Consider monitor DPIs
use constant AREA       => 1260; # A4 row area (1260 square millimeters)
use constant PDF_API2   => 100; 
use constant CAM_PDF    => 101; 

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
sub open_doc
{
    my ($self, $document) = @_;

    if (not defined $document) {
        $self->log->error("No document was provided");
        return 0;
    }

    if (not stat ($document)) {
        $self->log->error("Cannot find document $document");
        return 0;
    }

    # Check for file type    
    my $ft = File::Type->new();
    my $type = $ft->mime_type($document);

    if ($type !~ /tif/) {
        $self->log->error("Document $document is not a valid TIFF image") if $self->log;
        return 0;
    }

    $self->{'DOC'} = 1;
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

    my $doc = $self->{'DOC'};
    if (not defined $doc) {
        $self->log->error("No document was ever opened");
        return undef;
    }

    return 1; 
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
    $temp_dir .= "/"._generateUUID();
    rmtree ($temp_dir) if stat ($temp_dir);
    mkdir ($temp_dir);
    copy($doc, $temp_dir);
    my $file_name = basename($doc);
    my $filepath = $temp_dir."/".$file_name;

    my $ocr_OK = 1;
    my $confidence;
    my $ocr_text;
    my @rot_angles = (90, 270);
    # If size is too small, skip it
    if (_checkSize($filepath, DPI, AREA)) {
        # TODO should we force text encoding here as well ?!?
        $ocr_text = get_ocr($filepath, undef, 'ita');
        $confidence = $self->_getConfidence(\$ocr_text);
        # If image confidence is below threshold, try to rotate
        # it, in case it was badly oriented
        if (not defined $confidence) {
            $ocr_OK = 0;
        } elsif (defined $ocr_threshold && $confidence <= $ocr_threshold) {
            my $max_conf = 0;
            my $imager;
            my $rotated_ocr_text;
            foreach my $rot_angle (@rot_angles) {
                $imager = Imager->new(file=>$filepath) if not defined $imager;
                my $rotated = $imager->rotate(degrees => $rot_angle);
                $rotated->write(file => $filepath);
                $rotated_ocr_text = get_ocr($filepath, undef, 'ita');
                $confidence = $self->_getConfidence(\$rotated_ocr_text);
                if (not defined $confidence) {
                    $ocr_OK = 0;
                } elsif (($confidence > $max_conf) && ($confidence > $ocr_threshold)) {
                        $max_conf = $confidence;
                        $ocr_text = $rotated_ocr_text;
                }
            }
            # If its confidence is still below threshold, discard it;
            # it's probably garbage and it would lower the total
            # page confidence
            if ($max_conf > 0) {
                $confidence = $max_conf;
            } else {
                $ocr_OK = 0;
            }
        }
    } else {
        $ocr_OK = 0;
    }
    $text .= "\n".$ocr_text if $ocr_OK;

    rmtree($temp_dir) if stat ($temp_dir);

    $self->log->debug("Confidence: $confidence");
    $self->log->debug("Text      :\n\n$text");
    return ($text, $confidence);
}

#=============================================================

=head1 _getConfidence

=head2 INPUT
    $text:          reference to text

=head2 OUTPUT
    $confidence:    minimum confidence (if more than one page
                    was present)

=head2 DESCRIPTION

    Parses text looking for confidence

=cut

#=============================================================
sub _getConfidence
{
    my ($self, $text) = @_;
    
    my $confidence = 100;
    my $found = 0;

    while ($$text =~ /average_doc_confidence\:(\d{1,})/g) {
        $confidence = $1 if ($1 < $confidence);
        $found = 1;
    }

    if ($found) {
        $$text =~ s/average_doc_confidence\:\d{1,}//gi;
        return $confidence;
    } else {
        return undef;
    }
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

#=============================================================

=head2 ConvertToPDF

=head3 INPUT
    
    $out_file:          full path to converted PDF

=head3 OUTPUT

    $result:            1 if succesful, 0 otherwise

=head3 DESCRIPTION

Converts an HTML document into a PDF

=cut

#=============================================================
sub ConvertToPDF
{
    my ($self, $out_file) = @_;

    if (not stat $self->{'DOC_PATH'}) {
        $self->log->error("No input file was specified");
        return 0;
    }

    # Convert document using tiff2pdf
    my $cmd = "tiff2pdf -p A4 -o ".$out_file." ".$self->{'DOC_PATH'}." >/dev/null 2>&1";
    my $ret = system($cmd);

    if (($ret) || (not stat $out_file)) {
        $self->log->error("Error while converting file ".$self->{'DOC_PATH'});
        return 0;
    }

    return 1;
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




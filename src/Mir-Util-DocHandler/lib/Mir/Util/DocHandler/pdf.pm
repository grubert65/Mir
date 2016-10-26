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

=head2 ACKNOWLEDGEMENTS

Marco Masetti <marco.masetti at softeco.it> reviewed code.

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
with    'Mir::Util::R::DocHandler', 
        'Mir::Util::R::OCR',
        'Mir::Util::R::PDF',
        'Mir::R::PluginHandler';

use open qw(:std :utf8);
use Image::Size                 qw( imgsize );
use Imager                      ();
use File::Basename              qw( dirname basename fileparse );
use Mir::Util::ImageHandler     ();
use File::Which                 qw(which);
use File::Path                  qw( make_path remove_tree );

# use constant AREA          => 1260; # A4 row area (1260 square millimeters)
use constant DPI            => 72; # Consider monitor DPIs
use constant AREA           => 126; 
use constant PDF_API2       => 100; 
use constant CAM_PDF        => 101; 
use constant CAM_PDF_CONF   => 95; 
use constant PDF_INFO_CONF  => 90; 

use vars qw( $VERSION  );

# 0.01 : first stable release

$VERSION = '0.02';

has 'plugins' => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    trigger => \&_register_plugins
);

binmode STDOUT, ":encoding(UTF-8)";

sub _register_plugins {
    my ( $self, $plugins ) = @_;
    $self->register_plugins( $plugins );
}
#=============================================================

=head2 page_text

=head3 INPUT

$page: page number, all if not passed...

=head3 OUTPUT

$text:        Text of page if successful, undef if not
$confidence:  Estimated accuracy of extracted text

=head3 DESCRIPTION

Returns text of desired page of document
Workflow:
- returns if doc not opened
- creates a temporary folder to store extracted images
- get text using pdftotext first (doesn't work with images...)
- then looks for images to process with OCR. In this case
  language used by the OCR needs to be set via the lang attribute.

=cut

#=============================================================
sub page_text {
    my ( $self, $page ) = @_;

    my $text = "";
    my $confidence = 100;
    my ($f_page, $l_page) = ($page) ? ($page, $page):(1, $self->num_pages);

    my $pdftotext_bin = which('pdftotext');
    unless ( $pdftotext_bin ) {
        $self->log->error("No pdftotext cmd, cannot extract text from PDF");
    }
    # Get text using pdftotext first...
    # pdftotext default encoding for output text is Latin1, we force to encode in utf8
    my $cmd = join (' ', 
        $pdftotext_bin,
        "-nopgbrk -enc UTF-8",
        "-f $f_page",
        "-l $l_page",
        '"'.$self->{doc_path}.'"',
        "$self->{temp_dir_root}/page.txt",
        "> /dev/null 2>&1");
    my $ret = system($cmd);
    if ($ret == 0) {
        open  (SINGLE_PAGE, "<:encoding(utf8)", "$self->{temp_dir_root}/page.txt");
        read  (SINGLE_PAGE, $text, (stat(SINGLE_PAGE))[7]);
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
    } else {
        $self->log->error("Unable to read text from document $self->{doc_path}");
        return (undef, 0);
    }

    # ...then look for images to process with OCR 
    my $ih = Mir::Util::ImageHandler->new();
    my $total_images = 0;
    foreach my $page_num ( $f_page .. $l_page ) {

        my $image_files = $ih->pdfimages(
            pdf_file => "$self->{doc_path}",
            page_num => $page_num,
            out_root => "$self->{temp_dir_root}/images/$self->{doc_name}",
            params   => '-png'
        );

        # get rid of all images too small...
        for ( 0 .. (scalar @$image_files - 1 )) {
            unless ( _checkSize($image_files->[$_], DPI, AREA) ) {
                splice( @$image_files, $_, 1);
            }
        }

        # now call all image pre processing plugins...
        # they should eventually update image file names...
        my $out_params = {};
        my $input_params = { image_files => $image_files };
        $self->call_registered_plugins({
            hook            => 'image_pre_processing',
            input_params    => $input_params,
            output_params   => \$out_params
        });

        $DB::single=1;
        $image_files = $input_params->{image_files};
    
        my $ocr_OK       = 0;
        my @rot_angles   = (90, 90, 90); #assume it is right first...

        foreach my $page_image (@$image_files) {
            $total_images++;
            my $ocr_text;
            my $ocr_conf;
            ( $ocr_text, $ocr_conf ) = $self->get_ocr( 
                $page_image, 
                "$self->{temp_dir_root}/$self->{doc_name}" 
            );
            if ( $ocr_conf <= $self->{OCR_THRESHOLD} ) {
                my $max_conf = 0;
                my $rotated_ocr_text;
                my $angle_total=0;
                $ih->open( $page_image ) or die $@;
                foreach my $rot_angle (@rot_angles) {
                    $ih->rotate($rot_angle);
                    my $rotated = $ih->write();
                    ($rotated_ocr_text, $ocr_conf) = $self->get_ocr(
                        $rotated, 
                        "$self->{temp_dir_root}/$self->{doc_name}" 
                    );
                    if (($ocr_conf > $max_conf) && ($ocr_conf > $self->{OCR_THRESHOLD})) {
                        $max_conf = $ocr_conf;
                        $ocr_text = $rotated_ocr_text;
                    }
                    last if ( $max_conf > $self->{OCR_VALID_THRESHOLD} );
                }
                # If its confidence is still below threshold, discard it;
                # it's probably garbage and it would lower the total
                # page confidence
                if ($max_conf > 0) {
                    $confidence += $max_conf;
                    $ocr_OK=1;
                }
            } else {
                $confidence += $ocr_conf;
                $ocr_OK=1;
            }
            $text .= "\n".$ocr_text if $ocr_OK;
        }
    }
    if ($total_images > 0) {
        $confidence /= $total_images;
    }

    # NOTE : maybe we could even get rid of this 
    # provided all images fall inside the temp_dir_root...
#     $ih->delete_all();

    return ($text, $confidence);
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


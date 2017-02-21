package Mir::Util::R::OCR;
#===============================================================================

=head1 NAME

Mir::Util::R::OCR - A role for all Mir::Util::DocHandler drivers 
                    that need to use an OCR...

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    # The driver...
    package Mir::Util::DocHandler::DriverX;
    use Moose;
    with 'Mir::Util::R::DocHandler', 'Mir::Util::R::OCR';

    1;

    # Using the driver...
    my $o = Mir::Util::DocHandler->create( driver => 'DriverX' );

    $o->open_doc( "/a/doc/path" );

    # eventually set supposed text language...
    $o->lang('eng');

    # obtain an image of the page to get processed, then...
    my ( $text, $confidence ) = $o->get_ocr( $img_file, $text_filename );

=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at softeco.it> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mir at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mir>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ...


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Marco Masetti.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 SUBROUTINES/METHODS

=cut

#===============================================================================
use Moose::Role;
use namespace::autoclean;
use Log::Log4perl           ();
use File::Which             qw(which);

has 'tesseract_bin' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $cmd = which('tesseract');
        die "Tesseract not found" unless $cmd;
        return $cmd;
    }
);

has 'lang' => (
    is  => 'rw',
    isa => 'Str',
    default => sub { 'ita' },
);

# under this threashold text is rejected.
has 'OCR_THRESHOLD' => ( 
    is      => 'rw', 
    isa     => 'Str',
    default => '70'
);

# if text extraction exceed this 
# confidence level, we assume to
# be valid...
has 'OCR_VALID_THRESHOLD' => (
    is      => 'rw', 
    isa     => 'Str',
    default => '95'
);

#=============================================================

=head2 get_ocr - Extracts text from an image

=head3 INPUT

    $img_file     : the image file to extract text from
    $text_filename: text file root

=head3 OUTPUT

The text and confidence of the extraction

=head3 DESCRIPTION

Executes the tesseract binary and read the produced text file.
If confidence is computed along the text it is extracted otherwise
it is set to 100.

=cut

#=============================================================
sub get_ocr {
    my ( $self, $img_file, $text_filename ) = @_;

    $self->log->debug("Extracting text from $img_file");
    my $txt_file = $text_filename.".txt";
    unlink ( $txt_file ) if ( -e $txt_file );
    my $cmd = ( sprintf '%s %s %s', 
                 $self->{tesseract_bin}, 
                 "$img_file",
                 $text_filename
              ) .
              ( defined $self->lang ? " -l $self->{lang}" : '' ) .
              "  2>/dev/null";
    $self->log->debug("CMD: $cmd");
    my $ret = system ( $cmd );
    if ( $ret != 0 ) {
        die "Error executing tesseract for image \"$img_file\"";
    }
    die "Text file not found" unless ( -f $txt_file );
    my $text;
    {
        undef $/;
        open my $fh, "<", $txt_file;
        $text = <$fh>;
        close $fh;
    }
    my $confidence = 100;
    if ( $text =~ /average_doc_confidence:(\d{1,3})/ ) {
        $confidence = $1;
        $text =~ s/average_doc_confidence:(\d{1,3})//g;
    }
    if ( $confidence < $self->OCR_THRESHOLD ) {
        $self->log->warn("Confidence too low: text not valid");
    }
    return ( $text, $confidence );
}

1; # End of Mir::Util::R::OCR;
 


package Mir::Util::DocHandler::image;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::image - a Mir::Util::DocHandler driver to
extract text from any image format (handled by tesseract...)

=head1 VERSION

0.01

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    use Mir::Util::DocHandler;

    my $o = Mir::Util::DocHandler->create( driver => 'image' );
    $o->open_doc( $image_file );
    my $text = $o->page_text(1, '/tmp');

=head1 DESCRIPTION

A driver to get text out of any image format supported
by tesseract. 

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
use Moose;
use Image::OCR::Tesseract 'get_ocr';

with 'Mir::Util::R::DocHandler';

#=============================================================

=head2 pages

=head3 INPUT

=head3 OUTPUT

1

=head3 DESCRIPTION

Returns the number of pages for an image, 1 by default...

=cut

#=============================================================
sub pages {
    return 1;
}

sub page_text {
    my ( $self, $page_num, $temp_dir ) = @_;

    $temp_dir //= $ENV{CACHE_DIR} || '/tmp';
    my ( $text, $confidence ) = ( "", $self->CONFIDENCE );

    $text = get_ocr( $self->{DOC_PATH}, $temp_dir, 'ita' );
    if ( $text =~ /average_doc_confidence:(\d{1,3})/ ) {
        $confidence = $1;
        $text =~ s/average_doc_confidence:(\d{1,3})//g;
    }

    return ($text, $confidence);
}

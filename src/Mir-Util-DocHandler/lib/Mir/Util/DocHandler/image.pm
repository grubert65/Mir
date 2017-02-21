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
    my $text = $o->page_text(1);

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
with 'Mir::Util::R::OCR';
use namespace::autoclean;
use Image::OCR::Tesseract 'get_ocr';

extends 'Mir::Util::DocHandler';

sub page_text {
    my ( $self, $page_num ) = @_;

    $DB::single=1;
    my $temp_dir = $self->temp_dir_root;
    my ( $text, $confidence ) = $self->get_ocr(
        $self->doc_path,
        "$self->{temp_dir_root}/$self->{filename}-$page_num"
    );
    return ($text, $confidence);
}

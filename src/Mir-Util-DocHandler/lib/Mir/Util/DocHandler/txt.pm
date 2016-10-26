package Mir::Util::DocHandler::txt;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::txt - a Mir::Util::R::DocHandler driver to
get text from text files.

=head1 VERSION

0.0.1

=cut

our $VERSION='0.0.1';

=head1 SYNOPSIS

    use Mir::Util::DocHandler::txt;

    # refer to "L<Mir::Util::R::DocHandler>" documentation


=head1 DESCRIPTION

A Mir::Util::DocHandler driver for text files.


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
with 'Mir::Util::R::DocHandler';

#=============================================================

=head2 get_num_pages

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

Returns the number of pages (actually 1) for the text document

=cut

#=============================================================
sub get_num_pages {
    my $self = shift;
    return 1;
}

#=============================================================

=head2 page_text

=head3 INPUT

$page:                  page number (ignored)
$temp_dir:              temp dir where text is stored

=head3 OUTPUT

$text:                  Text of document if successful, undef 
                        if not. Page number is ignored 
$confidence:            Estimated accuracy of extracted text 
                        (100 if antiword was successful, 0
                        otherwise)

=head3 DESCRIPTION

Returns text of document and the confidence on it.
Currently implemented by each driver.

=cut

#=============================================================
sub page_text {
    my ($self, $page, $temp_dir) = @_;
    my $text;
    if ( -T "$self->{doc_path}" ) {
        local $/;
        my $fh;
        open ($fh, "<", "$self->{doc_path}" );
        $text = <$fh>;
        if ( $text ) {
        }
    }
    return ( $text, 100 );
}

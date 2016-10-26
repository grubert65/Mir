package Mir::Util::DocHandler::docx;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::docx - Driver class to handle 
Microsoft Word Office Open XML documents 

=head2 SYNOPSIS

    use Mir::Util::DocHandler;

    my $doc = Mir::Util::DocHandler->create( driver => 'docx' );
    my $text = $doc->page_text();

=head2 DESCRIPTION

This driver handles Microsoft Word documents, providing methods
for extracting text from them. Due to a lack of modules to handle
this type of documents, the number of pages cannot be determined
and text is extracted from the whole document.

=head2 EXPORT

None by default.

=head2 SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc <module>

=head2 SEE ALSO

=head2 AUTHOR

Marco Masetti <marco.masetti at softeco.it>

=head2 COPYRIGHT and LICENSE

Copyright (C) 2016 Marco Masetti.  All Rights Reserved.
Copyright (C) 2016 Softeco Sismat SpA.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

=head2 FUNCTIONS

=cut

#========================================================================
use Moose;
with 'Mir::Util::R::DocHandler';

sub get_num_pages {
    # not possible to detect the number of pages...
    return undef;
}

#=============================================================

=head2 page_text

=head3 INPUT

=head3 OUTPUT

$text:                  Text of document if successful, undef 
                        if not. Page number is ignored 
$confidence:            Estimated accuracy of extracted text,
                        100 by default

=head3 DESCRIPTION

Returns text of document

=cut

#=============================================================
sub page_text {
    my $self = shift;

    my $confidence = 100;
    my $cmd = "docx2txt.pl < \"$self->{doc_path}\"";
    my $text = `$cmd`;
    return ($text, $confidence);
}

1;

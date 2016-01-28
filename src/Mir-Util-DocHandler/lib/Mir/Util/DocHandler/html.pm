package Mir::Util::DocHandler::html;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::html - Driver class to handle 
HTML documents

=head2 SYNOPSIS

    use Mit::Util::DocHandler;

    my $doc = Mir::Util::DocHandler->create( driver => 'html' );

=head2 DESCRIPTION

This driver handles HTML documents, providing methods
for extracting text from them. Due to the nature of this type
of documents, the number of pages cannot be determined
and text is extracted from the whole document.

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

use Encode                      qw( from_to );
use LEOCHARRE::HTML::Text       qw( html2txt );

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

Stores document path in object

=cut

#=============================================================
sub open_doc
{
    my ($self, $document) = @_;

    unless (defined $document) {
        $self->log->error("No document was provided");
        return 0;
    }

    unless (stat ($document)) {
        $self->log->error("Cannot find document $document");
        return 0;
    }

    unless ( -T $document ) {
        $self->log->error("Document is not a text file");
        return 0;
    }

    $self->{'DOC_PATH'} = $document;

    return 1; 
}

#=============================================================

=head2 pages

=head3 INPUT

=head3 OUTPUT

Currently unavailable, always returns 1

=head3 DESCRIPTION

Currently unavailable, always returns 1

=cut

#=============================================================
sub pages
{
    my ($self) = shift;

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

Returns text of document

=cut

#=============================================================
sub page_text
{
    my ($self, $page, $temp_dir) = @_;

    my $confidence = 100;

    my $doc = $self->{'DOC_PATH'};

    my $text = undef;
    {
        local $/;
        open my $fh, "< $doc";
        $text=<$fh>;
        close $fh;
    }

    # Find weird encodings
    my $html;
    open DOC, "< $doc";
    read (DOC, $html, (stat(DOC))[7]);
    close DOC;
    
    if ($html =~ /charset\s*=\s*(.+)\"/) {
        my $converted;
        if ($1 !~ /utf/i) {    
            $converted = from_to($text, $1, 'utf8'); 
        }
        if ($converted == 0) {
            $converted = from_to($text, 'iso-8859-1', 'utf8'); 
        }
    }

    return ($text, $confidence);
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

    # Convert document using htmldoc
    my $cmd = "htmldoc --webpage -f $out_file ".$self->{'DOC_PATH'}." >/dev/null 2>&1";
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


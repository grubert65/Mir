package Mir::Util::DocHandler::rtf;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::rtf - Driver class to handle 
RTF documents

=head2 SYNOPSIS

    use Mir::Util::DocHandler::rtf;

    my $doc = Mir::Util::DocHandler::rtf->new();

=head2 DESCRIPTION

This driver handles RTF documents, providing methods
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
extends 'Mir::Util::DocHandler::Office';

use Time::HiRes                 qw(gettimeofday);
use File::Copy                  qw( copy );
use File::Basename              qw( basename );

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

    my $doc = $self->{'DOC_PATH'};
    if (not defined $doc) {
        $self->log->error("No document was ever opened");
        return undef;
    }

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

    my $doc = $self->{'DOC_PATH'};
    if (not defined $doc) {
        $self->log->error("No document was ever opened");
        return undef;
    }

    my $cmd = "catdoc \"$doc\" > $temp_dir/page.txt";
    my $ret = system($cmd);

    my $text = undef;
    if ($ret == 0) {
        open SINGLE_PAGE, "< $temp_dir/page.txt";
        read (SINGLE_PAGE, $text, (stat(SINGLE_PAGE))[7]);
        close SINGLE_PAGE;
        unlink "$temp_dir/page.txt";
    } else {
        $self->log->error("Unable to read page $page from document $doc");
        return (undef, 0);
    }

    return ($text, 100);
}

#=============================================================

=head2 ConvertToPDF

=head3 INPUT
    
    $out_file:          full path to converted PDF

=head3 OUTPUT

    $result:            1 if succesful, 0 otherwise

=head3 DESCRIPTION

Converts a MS Office document into a PDF

=cut

#=============================================================
sub ConvertToPDF {
    my ($self, $out_file) = @_;

    return undef unless $out_file;
    my $log = $self-> {LOG};

#    my $new_filepath;

    my $abiword = `which abiword`;
    if ( $abiword ) {
        my $cmd = "abiword --to=pdf --to-name=$out_file $self->{DOC_PATH}";
        system( $cmd ) == 0 or return undef;

        # ora dovrebbe aver generato un file con filepath eq DOC_PATH
        # ma con suffisso .pdf...
#        if ( $self->{DOC_PATH} =~ /\.(\w+)$/ ) {
#            my $length = length( $self->{DOC_PATH}) - length($1);
#            $new_filepath = substr( $self->{DOC_PATH},0, $length).'pdf';
#
#    copy($self->{'DOC_PATH'}, $in_conv_path);
#        }
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


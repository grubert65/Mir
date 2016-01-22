package Mir::Util::DocHandler::xls;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::xls - Driver class to handle 
Microsoft Excel documents

=head2 SYNOPSIS

    use Mir::Util::DocHandler;

    my $doc = Mir::Util::DocHandler::xls->new();

=head2 DESCRIPTION

This driver handles Microsoft Excel documents, providing methods
for converting them to PDF format. Due to a lack of modules 
to handle this type of documents, text extraction cannot be
performed

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

#=============================================================

=head2 pages

=head3 INPUT

=head3 OUTPUT

Currently unavailable, always returns undef

=head3 DESCRIPTION

Number of pages cannot be determined for Excel files, try 
converting it to PDF format using ConvertToPDF method.

=cut

#=============================================================
sub pages
{
    my ($self) = shift;

    $self->log->error("Number of pages cannot be determined for Excel
                files, try converting it to PDF format using
                ConvertToPDF method");

    return undef;
}

#=============================================================

=head2 page_text

=head3 INPUT

$page:                  page number (ignored)
$temp_dir:              temp dir where text is stored

=head3 OUTPUT

$text:                  always undef
$confidence:            always undef

=head3 DESCRIPTION

Text cannot be extracted from Excel files, try converting it 
to PDF format using ConvertToPDF method.

=cut

#=============================================================
sub page_text
{
    my ($self, $page, $temp_dir) = @_;

    $self->log->error("Text cannot be extracted for Excel
                files, try converting it to PDF format using
                ConvertToPDF method");

    return (undef, undef);
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


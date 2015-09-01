package Mir::Util::DocHandler::Office;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::Office - Base class to handle 
Microsoft Office documents, use specific class.

=head2 SYNOPSIS

    Do not use this class, use class that is specific to
    processed document (doc, rtf, xls)

=head2 DESCRIPTION

This driver provides basic methods to process Microsoft Office 
documents. Methods specific to each document type are provided
by subclasses.

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

use Time::HiRes                 qw(gettimeofday);
use File::Copy                  qw( copy );
use File::Basename              qw( dirname basename );

use constant OO_CHECK_COUNT => 40;
use constant OO_CHECK_SLEEP => 2;

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

    my $driver = (split(/::/, ref( $self ) ))[-1];

    if (not defined $document) {
        $self->log->error("No document was provided");
        return 0;
    }

    if (not stat ($document)) {
        $self->log->error("Cannot find document $document");
        return 0;
    }

    # Check if original file is an MS Office document
    if ($self->CheckFileType($document) !~ /$driver/i) {
        $self->log->error("$document is not an MSOffice document");
        return 0;
    }

    $self->{'DOC_PATH'} = $document;

    return 1; 
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
sub ConvertToPDF
{
    my ($self, $out_file, $display) = @_;

    if ((not defined $self->{'DOC_PATH'}) || 
        (not defined $out_file) || 
        (not defined $display)) {
        $self->log->("Input file name, output file name and display number must be provided");
        return 0;
    }

    if (not stat $self->{'DOC_PATH'}) {
        $self->log->error("No input file was specified");
        return 0;
    }

    # Copy original document to temp dir, in order to avoid
    # potentially invalid dirs for OOffice
    my $tmp_dir = $self->TEMP_DIR;
    if (not defined $tmp_dir) {
        $self->log->error("No temp dir is defined");
        return 0;
    }
    # Use temp filename, to be sure to give OOffice a proper path (it has problems 
    # with weird names)
    my ($seconds, $microseconds) = gettimeofday;
    my $filename = "$seconds".'_'."$microseconds";
    my $in_conv_path = $tmp_dir."/".$filename;
    my $out_conv_path = $tmp_dir."/".$filename.".pdf";
    copy($self->{'DOC_PATH'}, $in_conv_path);
    if (not stat ($in_conv_path)) {
        $self->log->error("Error occurred when copying ".$self->{'DOC_PATH'});
        return 0;
    }

    # Convert document
    my $out_path = Path::Class::Dir->new($out_file);
    $out_path = $out_path->absolute() if $out_path->is_relative();

    my $cmd = _office_cmd( $in_conv_path, $out_conv_path, $display);
    $self->log->debug("CMD: $cmd");

    my $found = 0;
    my $pid = fork();
    if ( $pid == 0 ) { # I'm the child...
        system( $cmd ) == 0
            or die "Error executing cmd $cmd";
        exit;
    } else {
        sleep(OO_CHECK_SLEEP);
        my $check_count = 0;
        while ((not $found) && ($check_count < OO_CHECK_COUNT)) {
            if (stat($out_conv_path)) {
                $found = 1;
                last;
            }   
            sleep(OO_CHECK_SLEEP);
            $check_count++;
        }
    }
    
    unlink($in_conv_path);
    if ($found) {
        copy($out_conv_path, $out_path);
        unlink($out_conv_path);
        if (not stat($out_path)) {
            $self->log->error("Error while copying converted file converting $out_path");
            return 0;
        }
        return 1;
    } else {
        $self->_killOOWriter($in_conv_path);
        return 0;
    }
}

sub _office_cmd {
    my ( $in, $out, $display ) = @_;
    my $cmd;

    if ( `which oowriter` ) {
        $cmd = "oowriter -display :$display";
        $cmd .= ' -invisible "macro:///Standard.Module1.ConvertWordToPDF(';
        $cmd .= "$in,$out)\"";
    }
    elsif ( `which libreoffice` ) {
        $out = dirname ( $out );
        $cmd = "libreoffice --headless --convert-to pdf:writer_pdf_Export --outdir $out $in";
    }
    elsif ( `which soffice`) {
        $cmd = "soffice -display :$display";
        $cmd .= ' -invisible "macro:///Standard.Module1.ConvertWordToPDF(';
        $cmd .= "$in,$out)\"";
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


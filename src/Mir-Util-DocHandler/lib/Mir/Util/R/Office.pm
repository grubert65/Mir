package Mir::Util::R::Office;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::R::Office - Moose fallback role with methods for any 
office doc with no specific handler

=head1 VERSION

0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    # for any office doc with no specific handler...
    package AnyDoc;
    use Moose;

    with 'Mir::Util::R::Office';
    1;


=head1 DESCRIPTION

This role provides already implementation of Mir::Util::R::DocHandler
required methods for generic office documents.
It tries to first convert office doc to pdf and then extract the 
text from pdf using the configured pdf driver.

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
use Moose::Role;
use feature 'unicode_strings';
use Mir::Util::DocHandler;
use File::Copy              qw( copy );
use File::Remove            qw( remove );
use Time::HiRes             qw(gettimeofday);
use Data::UUID;
use Encode;

with 'Mir::Util::R::DocHandler';

has 'pdf_dh' => (
    is => 'ro',
    isa => 'Mir::Util::DocHandler::pdf3',
    lazy    => 1,
    default => sub {
        return Mir::Util::DocHandler->create( driver => 'pdf3' );
    }
);

#=============================================================

=head1 CheckFileType

=head2 INPUT
    $file:          full path to file

=head2 OUTPUT
    $ret:           file type if successful, undef otherwise

=head2 DESCRIPTION

    Checks for file type
    NOTE : potentially to be moved somewhere

=cut

#=============================================================
sub CheckFileType {
    my ($self, $file) = @_;

    if (not stat $file) {
        $self->log->error("Cannot open file $file");
        return undef;
    }

    my $type;

    # Check for Excel and Word documents
    my $infos;
    my ($seconds, $microseconds) = gettimeofday;
    my $info_file = $self->{'TEMP_DIR'}."/"."$seconds"."_"."$microseconds";
    my $cmd = "antiword \"$file\" 2> $info_file 1> /dev/null";
    my $ret = system($cmd);

    if (stat ($info_file))
    {
        open FILE_INFO, "< $info_file";
        read (FILE_INFO, $infos, (stat(FILE_INFO))[7]);
        close FILE_INFO;
        unlink $info_file;
        if ($infos =~ /excel/gi) {
            return 'xls';
        } elsif ($infos =~ /rich text format/gi) {
            return 'rtf';
        } elsif (($ret == 0) && ($infos eq '')) {
            return 'doc';
        }
    }

    if (($ret != 0) && (not defined $type)) {
        # If not successful, use catdoc
        $cmd = "catdoc -v \"$file\" > $info_file";
        $ret = system($cmd);
    }

    if (stat ($info_file))
    {
        open FILE_INFO, "< $info_file";
        read (FILE_INFO, $infos, (stat(FILE_INFO))[7]);
        close FILE_INFO;
        unlink $info_file;
        if ($infos =~ /This is document \(DOC\) file/gi) {
            return 'doc';
        }
    }

    # If no type was found, use File::Type
    if (not defined $type) {
        my $ft = File::Type->new();
        $type = $ft->mime_type($file);
    
        $type =~ s/.+\///;
        if ($type =~ /word/) {
            return "doc";
        }
        return $type;
    }

    return undef;
}

#=============================================================

=head2 _killOOWriter

=head3 INPUT
    $doc_name:      document name
    
=head3 OUTPUT

=head3 DESCRIPTION

Kills OpenOffice Writer

=cut

#=============================================================
sub _killOOWriter {
    my ($self, $doc_name) = @_;

    my ($seconds, $microseconds) = gettimeofday;
    my $ps_file =  "$seconds".'_'."$microseconds";
    my $cmd = "ps -ef|grep writer.*$doc_name|grep -v grep > /tmp/$ps_file";
    my $ret = system($cmd);
    if ($ret == 0) {
        open INFO, "< /tmp/$ps_file";
        while (<INFO>) {
            my $infos = $_;
            my $user = $1 if ($infos =~ /(.*?)\s/);
            my @pids;
            while ($infos =~ /$user\s*(\d{1,})\s*.*$doc_name/g) {
                push @pids, $1;
            }
            $cmd = "kill -9 @pids";
            system($cmd);
        }
        close INFO;
        unlink ("/tmp/$ps_file") if (stat("/tmp/$ps_file"));
    } else {
        $self->log->error("Error while converting file $doc_name");
    }
}

#=============================================================

=head2 page_text

=head3 INPUT

    $page_num: page number (defaults to 1 for this driver...)
    $temp_dir: temp dir to use
    $lang    : supposed language of text (not mandatory)

=head3 OUTPUT

An array with fields:

=over 

=item   [0]: the document text
=item   [1]: the confidence

=back

=head3 DESCRIPTION

Tries to extract text from generic office document.
Workflow:
- tries to convert doc to pdf using libreoffice
- tries to extract text from generated pdf.

=cut

#=============================================================
sub page_text {
    my ( $self, $page_num, $temp_dir, $lang ) = @_;

    my ($text, $confidence) = (undef, undef);

    my $temp = $temp_dir || '/tmp';

    my $ug=Data::UUID->new;my $u=$ug->create();
    my $uuid = $ug->to_string($u);
    my $suffix = (split(/\./, $self->{DOC_PATH}))[-1];
    return ( $text, $confidence ) unless ( $suffix );

    my $temp_office_doc = $temp.'/'.$uuid.".$suffix";

    $self->log->debug("Copying file $self->{DOC_PATH} to $temp_office_doc");

    my $ret = copy( $self->{DOC_PATH}, $temp_office_doc );
    unless ( $ret ) {
        $self->log->error("Error copying file, no text extracted");
        return ($text, $confidence);
    }
    
    $self->log->info("Trying to extract text with libreoffice...");

    if ( `which libreoffice` ) {
        my $cmd = "libreoffice --headless --convert-to pdf:writer_pdf_Export $temp_office_doc --outdir $temp";
        $ret = system( $cmd );
        if ( $ret != 0 ) {
            $self->log->error("Error converting to pdf: $!");
            remove $temp_office_doc;
            return ($text, $confidence);
        }
        my $pdf =  $temp.'/'.$uuid.'.pdf';
        if ( -e $pdf ) {
            $self->pdf_dh->open_doc( $pdf );
            foreach my $page_num ( 1..$self->pdf_dh->pages() ) {
                my ( $t, $c ) = $self->pdf_dh->page_text( $page_num, $temp, $lang );
                $text .= encode('UTF-8', $t);
                $confidence += $c;
            }
            $confidence = $confidence / $self->pdf_dh->pages();
            remove $temp_office_doc;
            remove $pdf;
        } else {
            $self->log->error("Error creating the pdf file");
        }
    }
    return ( $text, $confidence );
}


1;

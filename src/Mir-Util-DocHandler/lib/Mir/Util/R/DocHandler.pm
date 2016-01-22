package Mir::Util::R::DocHandler;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::R::DocHandler - A role implemented by each Mir::Util::DocHandler
drivers

=head1 VERSION

0.01

=cut

our $VERSION='0.01';

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 AUTHOR

Andrea Poggi (andrea.poggi @ softeco.it )

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
use Archive::Extract                        ();
use Archive::Zip                            qw( :ERROR_CODES :CONSTANTS );
use File::Basename                          qw( dirname basename );
use DirHandle                               ();
use File::Copy                              qw( copy );
use File::stat                              ();
use File::Path                              qw( mkpath );
use File::Type                              ();
use Path::Class                             ();
use XML::Simple                             qw( XMLin XMLout );
use Cwd                                     qw( cwd );
use Log::Log4perl                           ();
use Time::HiRes                             qw(gettimeofday);
use namespace::autoclean;

has 'TEMP_DIR' => ( 
    is => 'rw', 
    isa => 'Str',
    default => '/tmp'
);

has 'OCR_THRESHOLD' => ( 
    is => 'rw', 
    isa => 'Str',
    default => '70'
);
has 'CONFIDENCE' => ( 
    is => 'rw', 
    isa => 'Str',
    default => '100'
);

has 'log' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Log::Log4perl->get_logger( __PACKAGE__ ); },
);

has 'params' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { return {} },
);

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

    if (not defined $document) {
        $self->log->error("No document was provided");
        return 0;
    }

    if (not stat ($document)) {
        $self->log->error("Cannot find document $document");
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

    $self->log->error("Use proper DocHandler to process document");

    return 0;
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

    $self->log->error("Use proper DocHandler to process document");

    return (undef, 0);
}
#=============================================================

=head1 CheckFileType

=head2 INPUT
    $file:          full path to file

=head2 OUTPUT
    $ret:           file type if successful, undef otherwise

=head2 DESCRIPTION

    Checks for file type

=cut

#=============================================================
sub CheckFileType
{
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
    my $cmd = "antiword $file 2> $info_file 1> /dev/null";
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

1; # End of Mir::Util::DocHandler

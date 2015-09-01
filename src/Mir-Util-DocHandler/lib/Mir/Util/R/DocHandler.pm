package Mir::Util::R::DocHandler;

use strict;
use warnings;

=head1 NAME

Mir::Util::DocHandler - The great new Mir::Util::DocHandler!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Mir::Util::DocHandler;

    my $foo = Mir::Util::DocHandler->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Andrea Poggi, C<< <andrea.poggi at softeco.it> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mir-util-dochandler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mir-Util-DocHandler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mir::Util::DocHandler


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mir-Util-DocHandler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mir-Util-DocHandler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mir-Util-DocHandler>

=item * Search CPAN

L<http://search.cpan.org/dist/Mir-Util-DocHandler/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Andrea Poggi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

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

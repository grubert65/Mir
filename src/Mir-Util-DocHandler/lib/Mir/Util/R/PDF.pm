package Mir::Util::R::PDF;
#===============================================================================

=head1 NAME

Mir::Util::R::PDF - A small role with all behaviour, attributes and methods
useful when handling a pdf file.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Consume this role when needed.

=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at softeco.it> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mir at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mir>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mir::Util::R::PDF


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Marco Masetti.

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

=head1 SUBROUTINES/METHODS

=cut

#===============================================================================
use Moose::Role;
with 'Mir::Util::R::DocHandler';
use File::Which    qw(which);

#=============================================================

=head2 get_num_pages

=head3 INPUT

=head3 OUTPUT

The number of pages or undef in case or errors.

=head3 DESCRIPTION

Tries to compute the number of pages of the pdf file.

=cut

#=============================================================
sub get_num_pages {
    my $self = shift;

    my $pdfinfo_bin = which 'pdfinfo';
    unless ( $pdfinfo_bin ) {
        $self->log->error( "pdfinfo cmd not found, not possible to compute number of pages" );
        return undef;
    }

    my $cmd = "$pdfinfo_bin \"$self->{doc_path}\" > $self->{temp_dir_root}/pdf_info_file.txt 2>&1";
    my $ret = system($cmd);
    if ($ret == 0) {
        # Get infos and delete temp dir...
        my $infos;
        open (PDF_INFO, "<:encoding(utf8)", "$self->{temp_dir_root}/pdf_info_file.txt");
        read (PDF_INFO, $infos, (stat(PDF_INFO))[7]);
        close (PDF_INFO);
        
        # If everything was OK, get document infos
        if ($infos =~ /pages\:.*?(\d{1,})/i) {
            return $1;
        } else {
            $self->log->error("Cannot get document $self->{doc_path} infos");
            return undef;
        }
    } else {
        # Sorry, no way to handle this document...
        $self->log->error("Cannot open document $self->{doc_path} with any tool, giving up");
        return undef;
    }
}

1; 
 


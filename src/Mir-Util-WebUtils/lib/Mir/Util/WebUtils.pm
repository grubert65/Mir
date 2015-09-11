our $VERSION = '0.01';

package Mir::Util::WebUtils;
=head1 NAME

Mir::Util::WebUtils - This is the base class to handle web pages.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This is the base module for handling and navigating web pages.
It features the Mir::Util::R::WebUtils role, that provides all methods
needed to navigate the DOM, plus some general utilities to read/write
a cache, to check file types and to perform useful operations (check
dates, handle items in an array, etc).
Note that this module does not retrieve page content from web, it 
must be set using SetPageContent method. 
Here follows module usage.

    use Mir::Util::WebUtils;

    my $wu = Mir::Util::WebUtils->new(
        TEMP_DIR => './data',
        CACHE_DIR => './test_data/cache',
        CACHE_NAME => 'test_web'
        );

    ...retrieve page from web...

    my $ret = $wu->SetPageContent($page_html);

=head1 EXPORT

Nothing to export

=head1 AUTHOR

Andrea Poggi, C<< <andrea.poggi at softeco.it> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mir-util-webutils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mir-Util-WebUtils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mir::Util::WebUtils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mir-Util-WebUtils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mir-Util-WebUtils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mir-Util-WebUtils>

=item * Search CPAN

L<http://search.cpan.org/dist/Mir-Util-WebUtils/>

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
use Moose;
use namespace::autoclean;

with 'Mir::Util::R::WebUtils';

1;

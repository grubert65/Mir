package Mir::R::Util;
#===============================================================================

=head1 NAME

Mir::R::Util - a role to import useful methods.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Moose;
    with 'Mir::R::Util';

    my ( $filename, $suffix ) = get_name_suffix( $path );

=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at softeco.it> >>

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

#=============================================================

=head2 get_name_suffix

=head3 INPUT

    $filename: a filename

=head3 OUTPUT

The name and suffix portion

=head3 DESCRIPTION

Splits the name from the suffix. Robust to some weird
file names (like ones with many dots...).

=cut

#=============================================================
sub get_name_suffix {
    my ( $self, $filename ) = @_;

    my ( $name, $suffix ) = ( $filename, undef );
    my @items = split(/\./, $filename);
    if ( @items > 1 ) {
        $suffix = pop @items;
        $name = join('.',@items);
    }
    return ( $name, $suffix );
}

1; 
 


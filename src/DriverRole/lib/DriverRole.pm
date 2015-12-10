package DriverRole;
#-----------------------------------------------------------------------

=head1 NAME

DriverRole - Ruolo che implementa il pattern Driver/Inteface.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    package Foo;
    use Moose::Role;
    with 'DriverRole';

    requires sub_a;

    package Main;
    use Moose;
    use Foo; # classe base (interface) di cui vogliamo un driver...

    my $foo_driver = Foo->create( driver => $driver );
    $foo_driver->sub_a();


=head1 SUBROUTINES/METHODS

=cut

#-------------------------------------------------------------------------
use Moose::Role;
use Moose::Util;
use namespace::autoclean;

#=============================================================

=head2 create

=head3 INPUT

An hash with keys:
    driver : the driver type the caller wants back
    params : (not mandatory) parameters passed to driver constructor

=head3 OUTPUT

A driver type object.

=head3 DESCRIPTION

Just creates and gives back a driver object...

=cut

#=============================================================
sub create {
    my ( $package, %fields ) = @_;
    my $driver = $fields{driver} or die "No driver passed!";
    my $params = $fields{params};

    my $class = _get_driver($package, $driver) or
        die ("$package driver '$driver' is not supported");
            
    # hand-off to specific implementation sub-class
    ( ref $params ) ? $class->new( $params ) : $class->new();
}

sub _get_driver {
    my $driver_type   = shift;
    my $driver_source = shift;

    # --- load the code
    eval "use ${driver_type}::$driver_source;";
    if ($@) {
        my $advice = "";
        if ($@ =~ /Can't find loadable object/) {
           $advice = "Perhaps ${driver_type}::$driver_source was statically "
                 . "linked into a new perl binary."
                 . "\nIn which case you need to use that new perl binary."
                 . "\nOr perhaps only the .pm file was installed but not "
                 . "the shared object file."
        }
        elsif ($@ =~ /Can't locate.*?$driver_type\/$driver_source\.pm/) {
          $advice = "Perhaps the ${driver_type}::$driver_source perl module "
                     . "hasn't been installed,\n"
                     . "or perhaps the capitalization of '$driver_source' "
                     . "isn't right.\n";
        }
        die("_getDriver() failed: $@: $advice\n");
    }
    "${driver_type}::$driver_source";

} # end of _get_driver


=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at softeco.it> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DriverRole

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Marco Masetti.

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

1; # End of DriverRole

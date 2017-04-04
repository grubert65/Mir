package Mir::Acq::Fetcher;
#===============================================================================

=head1 NAME

Mir::Acq::Fetcher - A base class every fetcher should inherit, not to use directly

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    package Mir::Acq::Fetcher::Driver;
    use Moose;
    with 'Mir::Acq::Fetcher';
    has 'foo' => (is => 'rw', isa => 'Num', default => 0);
    1;

    package Main;
    use Mir::Acq::Fetcher;
    my $f = Mir::Acq::Fetcher->create(
        driver => 'Driver',
        params => { foo => 1 }
    );

=head1 EXPORT

None

=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at softeco.it> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mir at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mir>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ...


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

=head1 SUBROUTINES/METHODS

=cut

#===============================================================================
use Moose::Role;
use namespace::autoclean;
use Log::Log4perl;

with 'DriverRole';

# the get_docs sub return code: 1 => ok, otherwise errors occurred while fetching
has 'ret'       => ( is => 'rw', isa => 'Int', default => 1 );

# a ref to the array of fetched docs. Each item should inherit from Mir::Doc
has 'docs'      => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

# in case fetching fails...
has 'errors'    => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

has 'log' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Log::Log4perl->get_logger( __PACKAGE__ ); },
);

# actually using the DriverRole role
# params gets passed directly as hash ref, not via 
# the params attribute...
# has 'params' => (
#     is      => 'rw',
#     isa     => 'HashRef',
#     lazy    => 1,
#     default => sub { return {} },
# );

requires 'get_docs';

#=============================================================

=head2 fetch

=head3 INPUT

=head3 OUTPUT

1/undef in case of errors.

=head3 DESCRIPTION

just try to get docs from the fetcher

=cut

#=============================================================
sub fetch {
    my $self = shift;

    $self->get_docs();

    unless ( $self->ret ) {
        $self->log->error( "Error fetching from fetcher: ".ref $self );
        foreach ( @{ $self->errors } ) {
            $self->log->error( $_ );
        }
    }
    return $self->ret;
}

1; 
 


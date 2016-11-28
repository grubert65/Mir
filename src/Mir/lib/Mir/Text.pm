package Mir::Text;
#===============================================================================

=head1 NAME

Mir::Text - a class that exposes some useful techniques used in IR.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Mir::Text;

    my $mt  = Mir::Text->new();
    $mt->load( $text );

    # list all concordances for term $term
    # concordances can be used to infer the common use of a term
    my $concordance = $mt->concordance( $term, $radius );

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

    perldoc Mir::Text;


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
use Moose;
use Log::Log4perl;

has 'text' => ( is => 'rw', isa => 'Str' );
has 'term' => ( is => 'rw', isa => 'Str' );
has 'log'  => (
    is => 'ro',
    isa=> 'Log::Log4perl::Logger',
    default => sub {
        return Log::Log4perl->get_logger;
    }
);

sub concordance {
    my ( $self, $radius ) = @_;

    unless ( $radius > 0 ) {
        $self->log->error( "Radius must be a positive number" );
        return undef;
    }

    my ($match, $pos, $start, $extract);
    my $width = 2*$radius;
    my @concordances;
    my $text = $self->text;
    
    $text =~ s/\n/ /g;
    $text =~ s/--/ -- /g;

    $DB::single=1;
    while ( $text =~ /\b($self->{term})\b/cg ) {
        $match = $1;
        $pos   = pos( $text );
        $start = $pos - $radius - length( $match );

        if ( $start < 0 ) {
            $extract = substr ( $text, 0, $width+$start+length($match));
            $extract = (" " x -$start ) . $extract;
        } else {
            $extract = substr ( $text , $start , $width+length($match));
        }
        push @concordances, $extract;
    }

    return \@concordances;
}
1; 
 


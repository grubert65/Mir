package Mir::R::PluginHandler;
#===============================================================================

=head1 NAME

Mir::R::PluginHandler - A role to be consumed by each class that wants to use plugins

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    package Foo;
    with 'Mir::R::PluginHandler';

    # Register a list of plugins for different
    # hooks...
    $self->register_plugins( {
        "hook1" => "P1",
        "hook2" => "P2",
    });

    #call all plugins registered for a hook...
    $self->call_registered_plugins(
        hook    => 'hook1',
        input_params    => $input,
        output_params   => $$out
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

    perldoc Mir::R::PluginHandler


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
use Mir::Plugin;
use Log::Log4perl;
use Data::Dumper qw( Dumper );
use TryCatch;

has 'plugins' => (is => 'rw', isa => 'HashRef');
has 'log' => (
    is  => 'rw',
    isa => 'Log::Log4perl::Logger',
    default => sub{ Log::Log4perl->get_logger( __PACKAGE__ ) }
);

#=============================================================

=head2 register_plugins

=head3 INPUT

    An HashRef with the list of plugins for each hook, like:

    {
        hook1   => ['P1','P2'],
        hook2   => 'P3'
    }

=head3 OUTPUT

1/undef in case of errors

=head3 DESCRIPTION

Stores the passed list of plugins

=cut

#=============================================================
sub register_plugins {
    my ($self, $plugins) = @_;

    $self->plugins( $plugins );
}

#=============================================================

=head2 call_registered_plugins

=head3 INPUT

It takes an hashref with keys:
    hook:           the hook for which we want to run the plugins
    input_params:   input params to pass to each registered plugin
    output_params:  a ref to an hashref to collect all plugins 
                    output

=head3 OUTPUT

=head3 DESCRIPTION

=cut

#=============================================================
sub call_registered_plugins {
    my ( $self, $params ) = @_;
    return undef unless ( $params->{hook} );

    $self->log->debug("Calling all plugins registered for hook: $params->{hook}");
    $self->log->debug("Input Params:");
    $self->log->debug( Dumper( $params->{input_params} ) );

    my $p = $self->plugins->{ $params->{hook} };

    try {
        foreach my $driver ( @$p ) {
            my $plugin = Mir::Plugin->create( driver => $driver );
            my $out = $plugin->run( $params->{input_params} );
            if ( ref $out eq 'HASH' ) {
                while ( my ( $k, $v ) = each( %$out ) ) {
                    $params->{output_params}->{$k} = {$v};
                }
            }
        }
    } catch {
        $self->log->error("Error executing plugin: $@");
    }

    return 1;
}

1; 
 
package Foo;
use Moose;
with 'Mir::R::PluginHandler';
1;

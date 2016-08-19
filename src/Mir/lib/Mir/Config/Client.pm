package Mir::Config::Client;
use feature "switch";
use Moose;
use namespace::autoclean;
use LWP::UserAgent;
use Log::Log4perl;
use JSON qw( decode_json );
use Data::Dumper qw( Dumper );
use TryCatch;

with 'DriverRole';

=head1 NAME

Mir::Config::Client - A client to interact with the Mir Config data store...

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

#    Note, this module implements the old API layer and interacts with the 
#    Mir::Config server directly. 
#    Look at pod in L<Mir::R::Config> rule for the new API model of
#    any Mir::Config::Client driver

# the old way to use the module was this:
#
    use Mir::Config::Client;

    # get a client connect to a specific Mir::Config server 
    my $c = Mir::Config::Client->new( 
        host => $host,
        port => $port
    ) or die "No server found at $host:$port...";

    # get a section item...
    my $item = $c->get_item( 
        section => $section,
        item    => $item 
    );

    # ...or get an item resource...
    my $resource = $c->get_resource( 
        section  => $section,
        item     => $item, 
        resource => $resource 
    );

    # ...or get any...
    my $hash = $c->get_any( section => $section )
        or die "Section $section does not exists...";

# the new way should be:
#
    my $o=Mir::Config::Client->create( 
            driver => 'Mongo', 
            params => {
                host    => 'localhost',
                port    => 27017,
                dbname  => 'MIR',
                section => 'system'
        } );
    $o->connect();
    my $fetchers = $o->get_key({tag=>'ACQ'},{fetchers=>1});



=head1 METHODS

=cut

has 'host'       => ( is => 'rw', isa => 'Str', default => sub { 'localhost' } );
has 'port'       => ( is => 'rw', isa => 'Str', default => sub { 5000 } );
has 'prefix'     => ( is => 'rw', isa => 'Str', default => sub { '/' } );
has 'query_path' => ( is => 'rw', isa => 'Str' );
has 'ua' => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        $ua->env_proxy;
        return $ua; 
    },
);

has 'log' => (is => 'ro',
    isa => 'Log::Log4perl::Logger',
    lazy => 1,
    default => sub {
        Log::Log4perl->get_logger( __PACKAGE__ );
    }
);

sub BUILD {
    my $self = shift;
    die "...mmm...it seems that we cannot reach internet..." 
        unless ( ( $self->{host} eq 'localhost' ) || $self->ua->is_online );

    $self->log->debug("Connecting to server:".$self->host);
    $self->log->debug("Connecting to port  :".$self->port);

    $self->query_path('http://'.$self->host.':'.$self->port);
    my $url = $self->{query_path}.$self->{prefix}."version";
    my $res = $self->ua->get( $url );
    die "No server found, calling URL: $url" unless $res->is_success;
    my $h = decode_json( $res->content );
    $self->log->debug("Mir::Config version: $h->{version}");
}

#=============================================================

=head2 get_item 

=head3 INPUT

An hash with keys:
- section : the Mir::Config section to point at
- item    : the section item to retrieve.

=head3 OUTPUT

An hashref or undef in case of errors.

=head3 DESCRIPTION

Retrieves the section item profile from the Mir::Config server.

=cut

#=============================================================
sub get_item {
    my ( $self, %params ) = @_;
    die "No item or section passed" unless ( defined $params{item} && defined $params{section} );
    my $query = $self->query_path.$self->prefix.$params{section}.'/'.$params{item}.'/';
    my $res = eval { $self->ua->get( $query ); };
    if ( $@ || not $res->is_success ) {
        $self->log->error( "Error retrieving item $params{item} for section $params{section}: ".$res->status_line );
        return undef;
    }
    my $h = decode_json( $res->content );
    $self->log->debug("Item $params{item} for section $params{section}:" );
    $self->log->debug( Dumper $h );
    return $h;
}

#=============================================================

=head2 get_resource

=head3 INPUT

An hash with keys:
- section : the Mir::Config section to point at
- item    : the section item 
- resource: the resource to retrieve

=head3 OUTPUT

An hashref or undef in case of errors.

=head3 DESCRIPTION

Retrieves the resource of the item for the section passed.

=cut

#=============================================================
sub get_resource {
    my ( $self, %params ) = @_;
    foreach ( qw(
        section
        item
        resource
    )) {
        die "No $_ passed" unless ( defined $params{ $_ } );
    }

    my $query = $self->query_path.$self->prefix.$params{section}.'/'.$params{item}.'/'.$params{resource};
    my $res = eval { $self->ua->get( $query ); };
    if ( $@ || not $res->is_success ) {
        $self->log->error( 
            "Error retrieving resource $params{resource }".
            "for item $params{item} ".
            "for section $params{section}: ".$res->status_line );
        return undef;
    }
    my $h = decode_json( $res->content );
    $self->log->debug("Resource:");
    $self->log->debug( Dumper $h );
    return $h->{ $params{resource} };
}

#=============================================================

=head2 get_any

=head3 INPUT

An hash with any of the following keys:
- section
- item (need section defined)
- resource (need both preceeding defined)

=head3 OUTPUT

An hashref or undef in case of errors.

=head3 DESCRIPTION

Given the input filter, provides back the configuration hash
that match the filter otherwise undef.

=cut

#=============================================================
sub get_any {
    my ( $self, $params ) = @_;

    my $h;
    my $res;
    my $query;

    try {
        $query = $self->query_path.$self->prefix;

        foreach ( qw(
            section
            item
            resource
        )) {
            $query .= $params->{$_}."/" if ( defined $params->{$_} );
        }
        $query = substr($query, 0, length ($query) - 1) if ($query =~ /\/$/);

        $self->log->debug( "Query string: $query" );
        $res = eval { $self->ua->get( $query ); };
        $h = decode_json( $res->content );

    } catch ( $e ) {
        $self->log->error( "Error retrieving query $query: $e" );

        return undef;
    }

    return $h;
}



=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at softeco.it> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mir-config-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mir-Config-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mir::Config::Client


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

1; # End of Mir::Config::Client

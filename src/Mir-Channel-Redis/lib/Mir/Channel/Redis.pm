package Mir::Channel::Redis;
use Moose;
use namespace::autoclean;

use Redis    ();
use JSON::XS qw( encode_json decode_json );
use Log::Log4perl;

has 'connect' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
);

has 'db'    => ( is => 'rw', isa => 'Int' );

has 'log'   => (
    is      => 'ro',
    isa     => 'Log::Log4perl::Logger',
    init_arg=> undef,
    default => sub { Log::Log4perl::get_logger( __PACKAGE__ ) },
);

has 'r' => (
    is  => 'rw',
    isa => 'Redis',
    lazy=> 1,
    default => sub { 
        my $self = shift;

        my $r = Redis->new( %{$self->connect} )
            or die "Error getting a Redis obj";
        $r->select( $self->{db} ) 
            if ( $self->{db} );
        return $r;
    },
    handles => [qw( publish subscribe unsubscribe )],
);

around 'publish' => sub {
    my $orig = shift;
    my $self = shift;

    my ( $channel, $message ) = @_;

    $message = encode_json( { message => $message } );
    $self->log->debug("[$channel]: Publishing Message $message");

    return $self->$orig( $channel, $message);
};

around 'subscribe' => sub {
    my $orig = shift;
    my $self = shift;

    my $orig_callback = pop;

    $self->$orig( 
        @_, 
        sub {
            my ($message, $channel, $subscribed_topic) = @_;
            $self->log->debug("[$channel]:Received $message");
            my $item = decode_json( $message );
            &$orig_callback($item->{message}, $channel, $subscribed_topic);
        },
    );
};

no Moose;
__PACKAGE__->meta->make_immutable;

#============================================================= -*-perl-*-

=head1 NAME

Mir::Channel::Redis - Redis driver that implements the interface Mir::Channel.

=head1 VERSION

0.01

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    use Mir::Channel ();

    my $c = Mir::Channel->create(
        driver  => 'Redis',
        params  => {
            connect => { server => '127.0.0.1:6379' }, 
            db      => 1,
        });

    # Subscribes to channels
    $c->subscribe(
        'acq-fetcher-system-alpha', 'acq-fetcher-rss-*',
        sub {
            my ($message, $topic, $subscribed_topic) = @_

            ## $subscribed_topic can be different from topic if
            ## you use psubscribe() with wildcards
        }
    );

    # Publish a message on a channel
    $c->publish(
        'acq-fetcher-system-alpha',
        { key => 'value }    # any scalar is fine...
    );

=head1 DESCRIPTION

Redis driver for the Mir::Channel role. Implements basic channel
operations on Redis. Please refer to the Publish/Subscribe Redis
API section for more details.


=head1 AUTHOR

Marco Masetti (grubert65 at gmail.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) Marco Masetti (grubert65 at gmail.com)

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SUBROUTINES/METHODS

=cut

#========================================================================

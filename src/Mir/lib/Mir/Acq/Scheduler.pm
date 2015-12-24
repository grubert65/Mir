package Mir::Acq::Scheduler;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Acq::Scheduler - base class that implements an acq scheduler

=head1 VERSION

0.02

=cut 

use vars qw( $VERSION );
# History
# 0.02: 15.12.2015 : now uses the new Mir::Config::Client API...
$VERSION='0.02';

=head1 SYNOPSIS

    use Mir::Acq::Scheduler;

    # this will load fetch
    my $scheduler = Mir::Acq::Scheduler->new(
        campaigns   => ['weather'],
        config_driver   => 'Mongo',
        config_params   => {
            host    => 'localhost',
            port    => 27017,
            dbname  => 'MIR',
            section => 'system'
        }
    ) or die "Error getting a Mir::Acq::Scheduler object";

    # get and enqueue all fetchers of the campaign
    # or the ones passed in input
    $scheduler->enqueue_fetchers_of_campaign();

=head1 DESCRIPTION

This class exports all methods usefull to implement an ACQ scheduler
that follows the Mir specifications.


=head1 AUTHOR

Marco Masetti (marco.masetti @ softeco.it )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SUBROUTINES/METHODS

=cut

#========================================================================
use Moose;
use namespace::clean;
use Queue::Q::ReliableFIFO::Redis ();
use Mir::Config::Client           ();
use Log::Log4perl;
use JSON                          qw( decode_json );

my $log = Log::Log4perl->get_logger( __PACKAGE__ );

has 'log'           => ( 
    is      => 'ro', 
    isa     => 'Log::Log4perl::Logger',
    default => sub { return Log::Log4perl->get_logger( __PACKAGE__ ) } 
);

has 'campaigns'     => ( is => 'rw', isa => 'ArrayRef', trigger => \&_set_queue );
has 'fetchers'      => ( is => 'rw', isa => 'ArrayRef' );
has 'fetcher_params'=> ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'queue_server'  => ( is => 'rw', isa => 'Str', default => "localhost" );
has 'queue_port'    => ( is => 'rw', isa => 'Int', default => 6379 );
has 'config_driver' => ( is => 'rw', isa => 'Str', default => 'Mongo' );
has 'config_params' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has 'queues'        => ( is => 'ro', isa => 'HashRef' );

sub _set_queue {
    my ( $self, $campaigns ) = @_;
    foreach my $campaign ( @$campaigns ) {
        if ( not defined $self->{queues}->{$campaign} ) {
            $self->{queues}->{$campaign} = Queue::Q::ReliableFIFO::Redis->new(
                server     => $self->queue_server,
                port       => $self->queue_port,
                queue_name => $campaign,
            ) or die "Error creating a queue for campaign $campaign\n";
    
            $self->log->debug("Created queue for campaign $campaign");
        }
    }
}

#=============================================================

=head2 enqueue_fetchers_of_campaign

=head3 INPUT

=head3 OUTPUT

the number of items added in queue/undef in case of errors
dies in case of errors.

=head3 DESCRIPTION

Gets the list of the fetchers configured for the campaign(s) and 
enqueue them in the queue for the campaign.
If a fetcher has the "split" config attribute set, then a set
of fetchers is added in the queue, one for each configured param
item.
Returns the number of enqueued items.

=cut

#=============================================================
sub enqueue_fetchers_of_campaign {
    my $self = shift;

    my @items;

    my $c = Mir::Config::Client->create( 
        driver => $self->config_driver,
        params => $self->config_params
    ) or die "No Mir::Config::Client object...\n";

    $c->connect() or die "Error connecting to a Mir::Config data store\n";

    my @fetchers;
    foreach my $campaign ( @{ $self->campaigns } ) {
        push @fetchers, @{ 
            $c->get_key(
                {
                    campaign => $campaign,
                    tag      => 'ACQ'
                },
                { 'fetchers' => 1 }
            )->[0]->{ fetchers };
        };

=begin  BlockComment  # BlockCommentNo_1

    my $fetchers = $c->get_key( 
        section  => 'system',
        item     => 'ACQ',
        resource => 'fetchers'
    );


=end    BlockComment  # BlockCommentNo_1

=cut

        foreach my $fetcher ( @fetchers ) {
            if ( defined $fetcher->{split} ) {
                die "No params section configured for fetcher" 
                    unless ( defined $fetcher->{params} );
                foreach ( @{ $fetcher->{params} } ) {
                    push @items, { 
                        ns => $fetcher->{ns},
                        %$_
                    };
                }
            } else {
                push @items, $fetcher;
            }
        }

        foreach my $item ( @items ) {
            $self->log->debug( "Adding fetcher $item->{ns} to campaign $campaign" );
            $self->{queues}->{$campaign}->enqueue_item( $item );
        }
    }
    return scalar @items;
}

1;

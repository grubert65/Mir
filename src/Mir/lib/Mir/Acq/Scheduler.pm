package Mir::Acq::Scheduler;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Acq::Scheduler - base class that implements an acq scheduler

=head1 VERSION

0.01

=head1 SYNOPSIS

    use Mir::Acq::Scheduler;

    my $scheduler = Mir::Acq::Scheduler->new(
        queue_server => 'localhost',
        queue_port   => 6379,
    ) or die "Error getting a Mir::Acq::Scheduler object";

    # check input params
    # if a campaign tag is found the corresponding
    # queue object is created
    $scheduler->parse_input_params();

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

use Queue::Q::ReliableFIFO::Redis   ();
use Mir::Config::Client             ();
use Log::Log4perl;
use Getopt::Long                    qw( GetOptions );

my $config;

my $log = Log::Log4perl->get_logger( __PACKAGE__ );

has 'queue_server'  => ( is => 'rw', default => 'localhost', trigger => \&_set_queue );
has 'queue_port'    => ( is => 'rw', default => 6379, trigger => \&_set_queue );
has 'config_server' => ( is => 'rw', default => 'localhost' );
has 'config_port'   => ( is => 'rw', default => 5000 );
has 'log'           => ( 
    is      => 'ro', 
    isa     => 'Log::Log4perl::Logger',
    default => sub { return Log::Log4perl->get_logger( __PACKAGE__ ) } 
);

has 'campaigns'     => ( is => 'rw', isa => 'ArrayRef', trigger => \&_set_queue );
has 'fetchers'      => ( is => 'rw', isa => 'ArrayRef' );
has 'params'        => ( is => 'rw', isa => 'Str' );
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

=head2 parse_input_params

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

=cut

#=============================================================
sub parse_input_params {
    my $self = shift;

    my @campaigns;
    my @fetchers;
    my $params;
    my $config_file;

    GetOptions ("campaign=s"        => \@campaigns,
                "fetcher=s"         => \@fetchers,
                "params=s"          => \$params,
                "config-file=s"     => \$config_file
    ) or die("Error in command line arguments\n");

    die "At least a campaign or a fetcher has to be configured\n" unless ( @campaigns || @fetchers );

    $self->campaigns ( \@campaigns  );
    $self->fetchers  ( \@fetchers   );
    $self->params( $params )            if ( defined $params );
    $self->config_file( $config_file )  if ( defined $config_file );

    return 1;
}

#=============================================================

=head2 enqueue_fetchers_of_campaign

=head3 INPUT

=head3 OUTPUT

the number of items added in queue/undef in case of errors
dies in case of errors.

=head3 DESCRIPTION

Gets the list of the fetchers configured for the campaign and 
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
    my $c = Mir::Config::Client->new(
        $self->{config_server},
        $self->{config_port}
    ) or die "No Mir::Config server found...";

    my $fetchers = $c->get_resource( 
        section  => 'system',
        item     => 'ACQ',
        resource => 'fetchers'
    );

    foreach my $fetcher ( @$fetchers ) {
        foreach my $campaign ( @{ $self->campaigns } ) {
            if ( $fetcher->{campaign} eq $campaign ) {
                if ( defined $fetcher->{split} ) {
                    die "No params section confired for fetcher" 
                        unless ( defined $fetcher->{params} );
                    foreach ( @{ $fetcher->{params} } ) {
                        push @items, { 
                            campaign    => $fetcher->{campaign},
                            ns          => $fetcher->{ns},
                            %$_
                        };
                    }
                } else {
                    push @items, $fetcher;
                }
            } 
        }
    }

    foreach my $item ( @items ) {
        $self->log->debug( "Adding fetcher $item->{ns} to campaign $item->{campaign}" );
        $self->{queues}->{$item->{campaign}}->enqueue_item( $item );
    }
    return scalar @items;
}

1;

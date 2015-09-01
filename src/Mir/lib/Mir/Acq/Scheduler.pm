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

    # fork the number of processors passed
    # wait for all processors death...
    # the single processor gets the first fetcher 
    # from the queue and executes it
    # otherwise exit
    $scheduler->fork_processors();

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
my $queues = {};

my $log = Log::Log4perl->get_logger( __PACKAGE__ );

has 'queue_server'  => ( is => 'rw', default => 'localhost', trigger => \&_set_queue );
has 'queue_port'    => ( is => 'rw', default => 6379, trigger => \&_set_queue );
has 'campaign'      => ( is => 'rw', isa => 'Str', trigger => \&_set_queue );
has 'processors'    => ( is => 'rw', default => 1 );
has 'queue'         => ( is => 'ro', isa => 'Queue::Q::ReliableFIFO'); # TODO the queue class is not right...

sub _set_queue {
    my ( $self, $v ) = @_;
        $self->queue( Queue::Q::ReliableFIFO::Redis->new(
            server     => $self->queue_server,
            port       => $self->queue_port,
            queue_name => $self->campaign
        ) or die "Error creating a queue for campaign $campaign_tag\n";
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

}

#=============================================================

=head2 enqueue_fetchers_of_campaign

=head3 INPUT

=head3 OUTPUT

the number of items added in queue/undef in case of errors
dies in case of errors.

=head3 DESCRIPTION

gets the list of the fetchers configured for the campaign and 
enqueue them in the queue for the campaign.
If a fetcher has the "split" config attribute set, then a set
of fetchers is added in the queue, one for each configured param
item.
Returns the number of enqueued items.

=cut

#=============================================================
sub enqueue_fetchers_of_campaign {
    my $self = shift;

}

#=============================================================

=head2 fork_processors

=head3 INPUT

=head3 OUTPUT

The number of processors forked or undef in case of error.

=head3 DESCRIPTION

Fork the number of processors passed (or the default one)

The single processor gets the first fetcher from the queue 
and executes it otherwise exit.

Wait for all processors death...

Dies in case of errors.

Returns the number of processors forked or undef
in case of errors.

=cut

#=============================================================
sub fork_processors {
    my $self = shift;
}

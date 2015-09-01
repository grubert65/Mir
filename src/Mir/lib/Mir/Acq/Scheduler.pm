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
    $scheduler->enqueue_fetchers_of_campaign();

    # fork the number of processors passed
    # if some fetchers have been configured, fork 
    # a processor for fetcher and pass fetcher namespace
    # to processor
    # wait for all processors death...
    # the single processor, if no fetcher has been passed,
    # gets the first fetcher from the queue and executes it
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
use YAML                            qw( Load );
use Mir::Config::Client             ();
use Log::Log4perl;
use Getopt::Long                    qw( GetOptions );

my $config;
my $queues = {};

{
    local $/;
    my $data = <DATA>;
    $config = Load( $data );
}

my $log = Log::Log4perl->get_logger( __PACKAGE__ );





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

1/undef in case of errors

=head3 DESCRIPTION

Get and enqueue all fetchers of the campaign

=cut

#=============================================================
sub enqueue_fetchers_of_campaign {
    my $self = shift;

}

#=============================================================

=head2 fork_processors

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

Fork the number of processors passed
if some fetchers have been configured, fork 
a processor for each fetcher and pass fetcher namespace
to processor

The single processor, if no fetcher has been passed,
gets the first fetcher from the queue and executes it
otherwise exit

wait for all processors death...

=cut

#=============================================================
sub fork_processors {
    my $self = shift;
}

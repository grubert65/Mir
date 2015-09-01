#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#  Application Documentation
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

=head1 NAME

mir-acq-scheduler.pl - Schedules ACQ processors configured in Mir::Config.

=head1 VERSION

0.0.1

=head1 USAGE

  perl mir-acq-scheduler.pl \
     --campaign <campaign tag> \
     --processors <max number of processors to fork> \
     --fetcher <fetcher namespace relative to Mir::Acq::Fetcher> \ # not mandatory
     --params <json-encoded string to be passed to any fetcher> \  # not mandatory
     --config-file <YAML-encoded file if config params (updates default ones)> # not mandatory

=head1 OPTIONS

=head1 DESCRIPTION

The official Mir ACQ scheduler. This script should be
scheduled via cron, and configured via input params.

See L<Mir::Acq::Scheduler> for help.

=head1 AUTHOR

Marco Masetti ( <marco.masetti@softeco.it> )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (<marco.masetti@softeco.it>). All rights reserved.

Followed by whatever licence you wish to release it under.
For Perl code that is often just:

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

use Moose;
use namespace::clean;
use Log::Log4perl                   qw( :easy );
use Mir::Acq::Scheduler ();

my $config;

{
    local $/;
    my $data = <DATA>;
    $config = Load( $data );
}

Log::Log4perl->easy_init( $DEBUG );

my $log = Log::Log4perl->get_logger( __PACKAGE__ );
my $acq = Mir::Acq::Scheduler->new( $config );

#--------------------------------------------------------------------------------
# parse input params
#--------------------------------------------------------------------------------
$scheduler->parse_input_params();

#--------------------------------------------------------------------------------
# get and enqueue all fetchers of the campaign
# (if a campaign tag has been configured...)
#--------------------------------------------------------------------------------
$scheduler->enqueue_fetchers_of_campaign();

#--------------------------------------------------------------------------------
# run all processors !!!
#--------------------------------------------------------------------------------
$scheduler->fork_processors();

exit(0); # end of the story...



TODO ----- CODICE VECCHIO DA RECUPERARE IN Mir::Acq::Scheduler...
#--------------------------------------------------------------------------------
# get list of fetchers from Mir::Config (using Mir::Config::Client...)
#--------------------------------------------------------------------------------
my $c = Mir::Config::Client->new() or die "No Mir::Config server found...";
my $fetchers = $c->get_resource( 
    section => 'system',
    item => 'ACQ',
    resource => 'fetchers'
);

foreach my $profile ( @$fetchers ) {
    die "No campaign defined for this fetcher\n" unless ( defined ( $profile->{campaign} ) );
    # create queue if not defined...
    if ( not defined $queues->{ $profile->{campaign} } ) {
        $queues->{$profile->{campaign}} = Queue::Q::ReliableFIFO::Redis->new(
            server  => $config->{QUEUE}->{server},
            port    => $config->{QUEUE}->{port},
            queue_name => $profile->{campaign},
        ) or die "Error creating a queue for campaign $profile->{campaign}\n";
    }

    if ( ($profile->{period} != 0) && ( $mins_since_epoch % $profile->{period} ) == 0 ) {
        $log->debug( "Adding fetcher $profile->{ns} to campaign $profile->{campaign}" );
        $queues->{$profile->{campaign}}->enqueue_item( $profile );
    }
}

__DATA__
QUEUE:
    queue_server: 'localhost'
    queue_port: 6379

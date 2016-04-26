#!/usr/bin/env perl
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
     --config_driver  <the Mir::Config::Client driver to use> (defaults to 'Mongo')
     --config_params  <json-encoded string with the Mir::Config::Client driver specific params>
     --queue_server   : the queue server, defaults to localhost
     --queue_port     : the queue port, defaults to 6379
     --fetcher <fetcher namespace relative to Mir::Acq::Fetcher> \ # not mandatory
     --fetcher_params <json-encoded string to be passed to any fetcher> \  # not mandatory

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

#--------------------------------------------------------------------------------
use Moose;
use namespace::clean;
use Log::Log4perl           qw( :easy );
use Getopt::Long            qw( GetOptions );
use Mir::Acq::Scheduler ();
use JSON                    qw( decode_json );

Log::Log4perl->easy_init( $DEBUG );

my @campaigns;
my @fetchers;
my $fetcher_params = {};
my $fetcher_params_json;

my $config_driver = 'Mongo';                    # defaults to driver Mongo
my $config_params = { section => 'system' };
my $config_params_json;
my $queue_server  = 'localhost';
my $queue_port    = 6379;

GetOptions ("campaign=s"        => \@campaigns,
            "fetcher=s"         => \@fetchers,
            "fetcher_params=s"  => \$fetcher_params_json,
            "config_driver=s"   => \$config_driver,
            "config_params=s"   => \$config_params_json,
            "queue_server=s"    => \$queue_server,
            "queue_port=i"      => \$queue_port
) or die("Error in command line arguments\n");

die "
Usage: $0 
 --campaign <campaign tag> \
 --config_driver  <the Mir::Config::Client driver to use> (defaults to 'Mongo')
 --config_params  <json-encoded string with the Mir::Config::Client driver specific params>
 --fetcher <fetcher namespace relative to Mir::Acq::Fetcher> \ # not mandatory
 --fetcher_params <json-encoded string to be passed to any fetcher> \  # not mandatory
 --queue_server <defaults to localhost>
 --queue_port <defaults to 6379>

At least a campaign or a fetcher has to be configured\n" unless ( @campaigns || @fetchers );

$config_params  = decode_json( $config_params_json ) if ( $config_params_json );
$fetcher_params = decode_json( $fetcher_params_json ) if ( $fetcher_params_json );

my $scheduler = Mir::Acq::Scheduler->new(
    campaigns       => \@campaigns,
    fetchers        => \@fetchers,
    fetcher_params  => $fetcher_params,
    queue_server    => $queue_server,
    queue_port      => $queue_port,
    config_driver   => $config_driver,
    config_params   => $config_params
);

#--------------------------------------------------------------------------------
# get and enqueue all fetchers of the campaign
# (if a campaign tag has been configured...)
#--------------------------------------------------------------------------------
$scheduler->enqueue_fetchers_of_campaign();

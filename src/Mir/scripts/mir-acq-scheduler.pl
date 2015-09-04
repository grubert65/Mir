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
use Log::Log4perl qw( :easy );
use YAML qw( Load );
use Mir::Acq::Scheduler ();

Log::Log4perl->easy_init( $DEBUG );

my $scheduler = Mir::Acq::Scheduler->new();

#--------------------------------------------------------------------------------
# parse input params
#--------------------------------------------------------------------------------
$scheduler->parse_input_params();

#--------------------------------------------------------------------------------
# get and enqueue all fetchers of the campaign
# (if a campaign tag has been configured...)
#--------------------------------------------------------------------------------
$scheduler->enqueue_fetchers_of_campaign();

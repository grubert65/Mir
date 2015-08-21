#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#  Application Documentation
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

=head1 NAME

mir-acq-scheduler.pl - Schedules ACQ processors configured in Mir::Config.

=head1 VERSION

0.0.1

=head1 USAGE

perl mir-acq-scheduler.pl

=head1 OPTIONS

=head1 DESCRIPTION

Workflow:

get list of fetchers from Mir::Config (using Mir::Config::Client...)
get mins since epoch
for each fetcher profile {
    if (not defined queue->{profile.campaign} ) {
    create queue for campaign
    }
    if (( $mins_since_epoch % profile.period ) == 0 ) {
        queue->{profile.campaign}.enqueue(profile.ns, profile.params);
    }
}

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.


=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for
system or program resources, or due to internal limitations of Perl
(for example, many modules that use source code filters are mutually
incompatible).


=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication
whether they are likely to be fixed in an upcoming release.

Also a list of restrictions on the features the module does provide:
data types that cannot be handled, performance issues and the circumstances
in which they may arise, practical limitations on the size of data sets,
special cases that are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.
Please report problems to <Maintainer name(s)>  (<contact address>)
Patches are welcome.

=head1 AUTHOR

Marco Masetti ( <marco.masetti@softeco.it>


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

use strict;
use warnings;
use Queue::Q::ReliableFIFO::Redis   ();
use DateTime                        ();
use YAML                            qw( Load );
use Mir::Config::Client             ();
use Log::Log4perl                   qw( :easy );

my $config;
my $queues = {};
my $ptable = {};

{
    local $/;
    my $data = <DATA>;
    $config = Load( $data );
}

Log::Log4perl->easy_init( $DEBUG );

my $log = Log::Log4perl->get_logger( __PACKAGE__ );

#--------------------------------------------------------------------------------
# Get mins from the epoch
#--------------------------------------------------------------------------------
my $mins_since_epoch = int ( DateTime->now()->epoch() / 60 );

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
    server: 'localhost'
    port: 6379

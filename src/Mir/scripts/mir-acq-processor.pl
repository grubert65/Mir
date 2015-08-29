#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-acq-processor.pl
#
#        USAGE: ./mir-acq-processor.pl  <campaign>
#
#  DESCRIPTION: gets the next fetcher for the campaign and executes it in an endless loop. 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 08/20/2015 05:19:35 PM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use utf8;
use Queue::Q::ReliableFIFO::Redis   ();
use Log::Log4perl                   qw( :easy );
use YAML                            qw( Load );

my $log = Log::Log4perl->get_logger( __PACKAGE__ );
my $config;

{
    local $/;
    my $data = <DATA>;
    $config = Load( $data );
}



my $campaign = $ARGV[0] or die "Usage: $0 <campaign tag>\n";
$log->debug("Executing fetchers for campaign: $campaign...");

my $q = Queue::Q::ReliableFIFO::Redis->new(
            server     => $config->{QUEUE}->{server},
            port       => $config->{QUEUE}->{port},
            queue_name => $campaign,
) or die "Error creating a queue for campaign $campaign\n";

while ( 1 ) {
    my $fetcher = $q->claim_item || { ns => 'Sleep' };

    my $class = $config->{FETCHER_NS_PREFIX}.'::'.$fetcher->{ns};

    eval {
        require $class;
        my $o = $class->new();
        $o->fetch();
        $q->mark_item_as_done($fetcher);
    };
    if ( $@ ) {
        $log->error( "Error getting an obj for fetcher $class");
        die "Error getting an obj for fetcher $class\n";
    }
}

__DATA__
FETCHER_NS_PREFIX: 'Mir::ACQ::Fetcher'
QUEUE:
    server: 'localhost'
    port: 6379

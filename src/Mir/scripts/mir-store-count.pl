#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-store-count.pl
#
#        USAGE: ./mir-store-count.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 05/01/2016 03:41:07 PM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use Mir::Doc;
use Mir::Store;
use JSON;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

my $host = $ARGV[0] || 'localhost';

my $json_str;

{
    local $/;
    $json_str = <DATA>
}

my $params = decode_json( $json_str );

foreach my $collection ( @{ $params->{collections} } ) {

    print "\n------------------ $collection ----------------------\n";
    my $client = Mir::Store->create(
        driver  => 'MongoDB',
        params  => {
            host        => $host,
            database    => 'MIR',
            collection  => $collection,
        }) or die "Error getting a Mir::Store object: $@\n";
    
    $client->connect();

    foreach my $status ( 0..5 ) {
        print "Number of docs in status $status: ";
        my $num = $client->count({status => $status});
        print "$num\n";
    }
}

__DATA__
{
    "collections":[
        "DocIndex_srvcluster1_commerciale",
        "DocIndex_srvcluster1_cv",
        "DocIndex_srvcluster1_eccairs",
        "DocIndex_srvcluster1_progetti",
        "DocIndex_srvcluster1_segreteria_priv",
        "DocIndex_srvcluster1_segreteria_pub",
        "DocIndex_srvcluster1_segreteria_ris",
        "DocIndex_srvcluster1_segreteria_usr"
    ]
}

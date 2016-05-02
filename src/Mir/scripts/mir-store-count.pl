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
use Moose;
use MongoDB;
use Mir::Doc qw( NEW INDEXED );
use utf8;
use JSON;
use Data::Printer;

my $json_str;

{
    undef $/;
    $json_str = <DATA>
}
my $params = decode_json( $json_str );

p $params;

my $client = MongoDB::MongoClient->new();
my $db = $client->get_database('MIR');

foreach my $collection ( @{ $params->{collections} } ) {
    my $c = $db->get_collection( $collection )
        or die "Error getting collection obj for collection $collection";

    foreach my $status ( (NEW INDEXED) ) {
        print "Number of docs in status $status: ";
        print $c->count({status => $status}); print "\n";
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

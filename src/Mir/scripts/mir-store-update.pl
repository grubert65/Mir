#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-store-update-status.pl
#
#        USAGE: ./mir-store-update-status.pl  
#                   --host       <MongoDB host> defaults to localhost
#                   --database   <MongoDB database>
#                   --collection <MongoDB collection>
#                   --update     <update json string as '{"$set":{"field":"value"}}'
#
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
#       AUTHOR: Marco Masetti (marco.masetti at softeco.it)
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 05/03/2016 09:55:23 AM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use utf8;
use Getopt::Long;
use Mir::Store ();
use JSON;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

my ($host, $database, $collection, $update_json, $filter_json) = ('localhost');

GetOptions(
    "host=s"        => \$host,
    "database=s"    => \$database,
    "collection=s"  => \$collection,
    "filter=s"      => \$filter_json,
    "update=s"      => \$update_json
) or die <<EOT;

        USAGE: ./mir-store-update-status.pl  
                   --host       <MongoDB host> defaults to localhost
                   --database   <MongoDB database>
                   --collection <MongoDB collection>
                   --filter     filter json string as '{"status":3}'
                   --update     update json string as '{"\$set":{"field":"value"}}'

EOT

unless ( $database && $collection && $update_json ) {
    die <<EOT;

        USAGE: ./mir-store-update-status.pl  
                   --host       <MongoDB host> defaults to localhost
                   --database   <MongoDB database>
                   --collection <MongoDB collection>
                   --filter     filter json string as '{"status":3}'
                   --update     update json string as '{"\$set":{"field":"value"}}'

EOT

}

my $update = decode_json( $update_json );
my $filter = ( defined $filter_json ) ? decode_json( $filter_json ) : {};

my $store = Mir::Store->create(
    driver => 'MongoDB',
    params => {
        host        => $host,
        database    => $database,
        collection  => $collection
}) or die "Error getting a Mir::Store object\n";

$store->connect() or die "Error connecting to store\n";

my $cursor = $store->find( $filter );

while ( my $doc = $cursor->next ) {
    unless ( $store->update( { '_id' => $doc->{_id} }, $update ) ) {
        print "Error updating document  with _id: ".$doc->{_id}->{value}."\n";
    }
}




#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: get_acq_fetchers.pl
#
#        USAGE: ./get_acq_fetchers.pl  
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
#      CREATED: 12/14/2015 03:41:41 PM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use utf8;
use MongoDB;
use MongoDB::OID;
use Data::Printer;

my $client     = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $database   = $client->get_database( 'MIR' );
my $collection = $database->get_collection( 'system' );

my @fetchers = $collection->find( {tag => 'ACQ'} )->fields({ fetchers => 1 } )->all();
p @fetchers;


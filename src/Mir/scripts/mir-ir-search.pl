#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-ir-search.pl
#
#        USAGE: ./mir-ir-search.pl <an index> <a match JSON-encoded string...> 
#
#  DESCRIPTION: 
#       Performs a query against an index, example:
#           this should return all docs in the "test" index:
#           perl ./mir-ir-search.pl "test" "{ \"match_all\": {} }"
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 02/23/2016 07:17:52 PM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use utf8;
use Search::Elasticsearch;
use JSON;
use Data::Printer;

my ($index, $query_json_str) = @ARGV
    or die "Usage: $0 <an index> <a match JSON-encoded string>";

my $query = decode_json ( $query_json_str );
my $e = Search::Elasticsearch->new();

my $results = $e->search(
    index => $index,
    body  => {
        query => $query,
    }
);

p $results;




#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-ir-search.pl
#
#        USAGE: ./mir-ir-search.pl 
#                   --index <an index> 
#                   --q_str <a match JSON-encoded string...> 
#                   --q_file <path to a JSON-encoded query file>
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
use Getopt::Long qw( GetOptions );
use TryCatch;

if ( scalar @ARGV < 2 ) {
    die <<EOT;

        USAGE: ./mir-ir-search.pl 
                   --index  <an index> 
                   --q_str  <a match JSON-encoded string...> 
                   --q_file <path to a JSON-encoded query file>
                   [--size   <size, defaults to 5>]
                   [--from   <from, defaults to 0>]

EOT
}

my ( $index, $q_str, $q_file, $size, $from ) = ("","","",5,0);

GetOptions (
    "index=s"   => \$index,
    "q_str=s"   => \$q_str,
    "q_file=s"  => \$q_file,
    "size=i"    => \$size,
    "from=i"    => \$from
) or die <<EOT;

        USAGE: ./mir-ir-search.pl 
                   --index <an index> 
                   --q_str <a match JSON-encoded string...> 
                   --q_file <path to a JSON-encoded query file>
                   [--size   <size defaults to 5>]
                   [--from   <from defaults to 0>]

EOT

unless ( ( $index ) && ( $q_str || $q_file ) )  {

    die <<EOT;
        USAGE: ./mir-ir-search.pl 
                   --index <an index> 
                   --q_str <a match JSON-encoded string...> 
                   --q_file <path to a JSON-encoded query file>
                   [--size   <size defaults to 5>]
                   [--from   <from defaults to 0>]

EOT
}

my $e = Search::Elasticsearch->new();
my $res = "no result";
my $query;

try {
    if ( $q_str ) {
        $query = decode_json ( $q_str );
    } elsif ( $q_file ) {
        die "File not found or not readable\n" unless ( -f $q_file );
        {
            local $/;
            open my $fh, "<", $q_file;
            $q_str = <$fh>;
            close $fh;
        }
        $query = decode_json ( $q_str );
    } 
    $res = $e->search(
        size  => $size,
        from  => $from,
        index => $index,
        body  => {
            query => $query,
        }
    );
} catch ( Search::Elasticsearch $err ) {
    print "Search error!\n";
    p $err;
}

p $res;




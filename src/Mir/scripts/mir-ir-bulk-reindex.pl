#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-ir-bulk-reindex.pl
#
#        USAGE: ./mir-ir-bulk-reindex.pl  
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
#      CREATED: 06/06/2016 01:22:14 PM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use Search::Elasticsearch;

die "Usage: $0 <old index> <new index> <doc type>\n" unless ( scalar @ARGV > 1 );

my ( $old_index, $new_index, $type ) = @ARGV;

print "Going to reindex all docs of type $type from $old_index to $new_index...\n";
print "OK ? (y/[n]): "; my $a = <STDIN>;chomp $a;
my $es = Search::Elasticsearch->new();
if ( $a eq 'y' ) {
    # Reindex docs:
    my $bulk = $es->bulk_helper(
        index   => $new_index,
        type    => $type,
        verbose => 1
    );
    $bulk->reindex( source => { index => $old_index });
}

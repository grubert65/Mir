#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-ir-create-index.pl
#
#        USAGE: perl mir-ir-create-index.pl 
#                   --config_driver <config_driver> 
#                   --config_params <config_params> 
#                   --doc_type <doc_type> 
#                   --index <index>
#
#  DESCRIPTION: Create an index eventually associating the mapping found in
#  config for the passed document type.
#
#       AUTHOR: Marco Masetti
#      VERSION: 1.0
#      CREATED: 05/31/2016 09:06:22 AM
#===============================================================================
use strict;
use warnings;
use utf8;
use TryCatch;
use Getopt::Long qw( GetOptions );
use JSON         qw( decode_json );
use Search::Elasticsearch;

use Mir::Config::Client;

if ( scalar @ARGV < 4 ) {
    die <<EOT;
Usage: $0 --config_driver <config_driver> --config_params <config_params> --doc_type <doc_type> --index <index>
EOT
}

my ( $config_driver, $config_params_json, $doc_type, $index );
GetOptions(
    "config_driver=s"       => \$config_driver,
    "config_params_json=s"  => \$config_params_json,
    "doc_type=s"            => \$doc_type,
    "index=s"               => \$index
) or die <<EOT;

Usage: $0 --config_driver <config_driver> --config_params <config_params> --doc_type <doc_type> --index <index>
EOT

my $json = JSON->new->allow_blessed;
my $params = ($config_params_json) ? $json->decode( $config_params_json ) : {};

my $config = Mir::Config::Client->create(
    driver  => $config_driver,
    params  => $params
) or die "Error getting a Mir::Config client\n";

$config->connect();

my $elastic_config = $config->get_key(
    { tag => 'elastic'},
    { mappings => 1 }
) or die "Error getting configuration section for Elastic\n";

my $es = Search::Elasticsearch->new();

print "Creating index $index for document type $doc_type...\n";
try {
    if ( exists $elastic_config->[0]->{mappings}->{$doc_type} ) {
        $es->indices->create(
            index   => $index,
            body    => { mappings => { $doc_type => $elastic_config->[0]->{mappings}->{$doc_type} } }
        ) or die "Error creating index $index for document $doc_type\n";
    } else {
        $es->indices->create( index => $index ) or die "Error creating index $index\n";
    }
} catch ( Search::Elasticsearch::Error $err ) {
    die "Error creating index $index : type $err->{type}\nMsg: $err->{text}\n";
}


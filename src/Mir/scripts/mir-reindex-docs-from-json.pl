#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: reindex-docs-from-json.pl
#
#        USAGE: ./reindex-docs-from-json.pl 
#                   --campaign <campaign tag> 
#                   --config_driver <config driver> [defaults to 'JSON']
#                   --config_params <config driver params>
#                   [--log_config_params] <Log::Log4perl config params>
#                   [--all] tries to reindex all docs
#                   [--no_text] tries to reindex only documents without text
#                   [--suffix <a suffix>] tries to reindex all docs with this suffix
#                   [--idx_id <an id>] tries to reindex only document with this idx id
#
#  DESCRIPTION:
#               Tries to reindex documents for all indexes pointed by the campaign
#               Workflow:
#               - get input params
#               - parse config params file
#               - connect to mongo db
#               - connect to elasticsearch
#               - determine action:
#                   - all => action=all
#                   - no_text   => action=no_text
#                   - suffix    => action=suffix, value=<suffix>
#                   - idx_id    => action=id, value=<id>
#
#               given( action ):
#                   /all/:
#                       - get all mongo docs
#                       - for each doc:
#                           - try index 
#                           - update mongo doc status (NOTE: no indexed_date?)
#                   /no_text/:
#                       - get all mongo docs
#                       - for each doc:
#                           - if no confidence found:
#                               - try index 
#                               - update mongo doc status (NOTE: no indexed_date?)
#                   /suffix/:
#                       - get all docs from mongo with suffix eq <suffix>
#                       - for each doc found:
#                           - try index 
#                           - update mongo doc status (NOTE: no indexed_date?)
#                   /id/:
#                       - get doc from mongo with idx_id eq <id>
#                       - try index
#                       - update mongo doc status (NOTE: no indexed_date?)
#
#
#       AUTHOR: Marco Masetti ( marco.masetti at softeco.it )
# ORGANIZATION: Softeco
#      VERSION: 1.0
#      CREATED: 04/26/2016 01:48:33 PM
#===============================================================================
use strict;
use warnings;
use utf8;
use Getopt::Long    'GetOptions';
use JSON            'decode_json';
use Search::Elasticsearch;
use Mir::Config::Client;
use Mir::Store;
use Mir::IR;
use Mir::Stat;


#===============================================================================
#               - get input params
#===============================================================================
my $campaign;
my $config_driver = 'JSON';
my ($config_params, $config_params_json);
my $log_config_params;
my $all_flag;
my $no_text_flag;
my $suffix;
my $doc_id;

if ( scalar @ARGV < 2 ) {

    die <<EOT;

        USAGE: $0 --campaign <campaign> 
                  --config_driver <config driver> [defaults to 'JSON']
                  --config_params <config driver params>
                  [--log_config_params] <Log::Log4perl config params>
                  [--all] tries to reindex all docs
                  [--no_text] tries to reindex only documents without text
                  [--suffix <a suffix>] tries to reindex all docs with this suffix
                  [--idx_id <an id>] tries to reindex only document with this idx id

EOT

}

GetOptions( "campaign=s"        => \$campaign,
            "config_driver=s"   => \$config_driver,
            "config_params=s"   => \$config_params_json,
            "log_config_params" => \$log_config_params,
            "all"               => \$all_flag,
            "no_text"           => \$no_text_flag,
            "suffix=s"          => \$suffix,
            "idx_id"            => \$doc_id
) or die <<EOT;

        USAGE: $0 --campaign <campaign> 
                  --config_driver <config driver> [defaults to 'JSON']
                  --config_params <config driver params>
                  [--log_config_params] <Log::Log4perl config params>
                  [--all] tries to reindex all docs
                  [--no_text] tries to reindex only documents without text
                  [--suffix <a suffix>] tries to reindex all docs with this suffix
                  [--idx_id <an id>] tries to reindex only document with this idx id

EOT

die "At least a campaign tag is needed...\n" unless ( $campaign );

#===============================================================================
#               - parse config params file
#===============================================================================
$config_params = decode_json( $config_params_json )
    or die "Error parsing system config parameters file";

my $config_client = Mir::Config::Client->create(
    driver  => $config_driver,
    params  => $config_params
) or die "Error getting a Mir::Config::Client object: $@\n";

$config_client->connect;

my $params = $config_client->get_key({campaign => $campaign},{params=>1})
    or die "Error getting config params for campaign $campaign: $@\n";

#===============================================================================
#               - connect to mongo db
#===============================================================================
my $store_params = $params->[0]->{params}->{fetchers}->[0]->{params}->{storage_io_params}->{io};
my $store = Mir::Store->create(
    driver  => $store_params->[0],
    params  => $store_params->[1]
) or die "Error getting a Mir::Store object\n";
$store->connect();

#===============================================================================
#               - connect to elasticsearch
#===============================================================================
my $e = Search::Elasticsearch->new( %{ $params->[0]->{params}->{idx_server}->{ir_params} } )
    or die "Error getting a Search::Elasticsearch object\n";

# in case I need to update the number of indexed docs for a campaign...
my $stat = Mir::Stat->new(
    counter => $campaign.'_indexed',
    select  => 10,
);

# processing user action...
if ( $all_flag ) {
my $docs = $store->find();
while ( my $doc = $docs->next() ) {
#                           - try index 
#                           - update mongo doc status (NOTE: no indexed_date?)


}

} elsif ( $no_text_flag ) {

} elsif ( $suffix ) {

} elsif ( $idx_id ) {

}

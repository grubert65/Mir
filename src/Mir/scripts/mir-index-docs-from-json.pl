#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: index-docs-from-json.pl
#
#        USAGE: ./index-docs-from-json.pl --campaign < a campaign >
#                                         --config_file <a JSON-encoded config file to use>
#                                         --docs_file <a JSON-encoded list
#                                           of Mir::Doc::File objects to
#                                           index>
#  DESCRIPTION: 
#   Index all doc profiles passed with the --docs_file params into an Elastic index
#   configured with the --config_file parameter. The campaign to look for is configured
#   with the --campaign parameter.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 02/17/2016 05:26:31 PM
#     REVISION: ---
#===============================================================================
use Moose;
use Getopt::Long            qw( GetOptions );
use Log::Log4perl           qw( :easy );
use JSON                    qw( decode_json );

use Mir::IR;

Log::Log4perl->easy_init( $INFO );
my $log = Log::Log4perl->get_logger( __PACKAGE__);

my $campaign;
my $config_file;
my $docs_file;
my $docs_json;

GetOptions ("campaign=s"    => \$campaign,
            "config_file=s" => \$config_file,
            "docs_file=s"   => \$docs_file,
) or die("Error in command line arguments\n");
die "
Usage: $0 
 --campaign <campaign tag> \
 --config_file  the configuration file
 --docs_file a JSON-encoded list of Mir::Doc::File objects to index\n" unless $campaign ;

 die "Configuration file not readable\n" unless ( -f $config_file );
 die "Docs file not readable\n" unless ( -f $docs_file );

{
    local $/;
    open my $fh, "<$docs_file";
    $docs_json = <$fh>;
    close $fh;
}

my $ir = Mir::IR->new(
    campaign      => $campaign,
    config_driver => 'JSON',
    config_params => {path => $config_file}
);

# config objects and create Elastic index (if not exists)...
# (see Mir::Config IR section in system collection)
$ir->config();

my $items = decode_json $docs_json;

foreach my $item ( @$items ) {
    $ir->_index_item( $item );
}


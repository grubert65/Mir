#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-ir.pl
#
#        USAGE: perl mir-ir.pl  --campaign <a campaign tag> 
#                               --config_driver <a Mir::Config::Client driver>
#                                               (defaults to Mongo)
#                               --config_params <a JSON-encoded string of
#                                               parameters for the Mir::Config::Client object>
#                               --log_config_params <a Log::Log4perl configuration script>
#
#  DESCRIPTION: This script implements the Mir::IR process.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Marco Masetti (marco.masetti@softeco.it)
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 02/16/2016 04:45:42 PM
#     REVISION: ---
#===============================================================================
use Moose;
use Getopt::Long            qw( GetOptions );
use Log::Log4perl           qw( :easy );
use JSON                    qw( decode_json );

use Mir::IR ();

my $campaign;
my $config_driver = 'Mongo';
my $config_params = { section => 'system' };
my $config_params_json;
my $log_config_params;

GetOptions ("campaign=s"            => \$campaign,
            "config_driver=s"       => \$config_driver,
            "config_params=s"       => \$config_params_json,
            "log_config_params=s"   => \$log_config_params,
) or die("Error in command line arguments\n");
die "

    Usage: $0 
     --campaign <campaign tag> \
     --config_driver     the Mir::Config::Client driver to use> (defaults to 'Mongo')
     --config_params     json-encoded string with the Mir::Config::Client driver specific params (defaults to section => 'system')
     --log_config_params path to a Log::Log4perl config file (if not provided logs will be directed to stdout)
    
    At least a campaign needs to be provided\n" 

unless $campaign ;

( $log_config_params ) ? Log::Log4perl->init( $log_config_params ) : Log::Log4perl->easy_init( $INFO );
my $log = Log::Log4perl->get_logger( __PACKAGE__);

$config_params = decode_json $config_params_json if ( $config_params_json );
my $ir = Mir::IR->new(
    campaign      => $campaign,
    config_driver => $config_driver,     # Mongo by default...
    config_params => $config_params
);

# config objects and create Elastic index (if not exists)...
# (see Mir::Config IR section in system collection)
$ir->config();

# consumes all items in queue
# for each document profile, get document text 
# and index it
$ir->process_items_in_queue();

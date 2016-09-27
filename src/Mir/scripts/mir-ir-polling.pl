#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-ir-polling.pl
#
#        USAGE: perl mir-ir-polling.pl  
#
#  DESCRIPTION: Gets the configuration params for the passed campaign and then
#               polls the Store for next document to index. Keeps polling until
#               no new document is found, then goes to sleep for some time.
#
#      OPTIONS: --campaign      <a campaign tag> 
#               --config_driver <a Mir::Config::Client driver> (defaults to Mongo)
#               [--config_params <a JSON-encoded string of params for the Mir::Config::Client object>]
#               [--log_config_params <a Log::Log4perl configuration script> (defaults to stdout)]
#        NOTES: ---
#       AUTHOR: Marco Masetti (marco.masetti at softeco.it)
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 05/02/2016 08:34:30 AM
#     REVISION: 0.1
#===============================================================================
use Moose;
use Getopt::Long    qw( GetOptions );
use Log::Log4perl   qw( :easy );
use JSON            qw( decode_json );
use utf8;
use Log::Log4perl   qw(:easy);
use Mir::IR         ();

my $campaign;
my $config_driver = 'Mongo';
my $config_params = { section => 'system', dbname => 'MIR' };
my $config_params_json;
my $log_config_params;
my $polling_period;

GetOptions ("campaign=s"            => \$campaign,
            "config_driver=s"       => \$config_driver,
            "config_params=s"       => \$config_params_json,
            "log_config_params=s"   => \$log_config_params,
            "polling_period=i"      => \$polling_period,
) or die("Error in command line arguments\n");
die "

    Usage: $0 
     --campaign <campaign tag> \
     --config_driver     the Mir::Config::Client driver to use> (defaults to 'Mongo')
     --config_params     json-encoded string with the Mir::Config::Client driver specific params (defaults to section => 'system')
     --log_config_params path to a Log::Log4perl config file (if not provided logs will be directed to stdout)
     --polling_period    number of seconds to wait when no more documents to be indexed are found
    
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

# keeps polling the Store for new items
$ir->process_new_items( $polling_period );


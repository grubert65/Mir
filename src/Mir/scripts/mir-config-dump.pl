#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-config-dump.pl
#
#        USAGE: ./mir-config-dump.pl  
#           --config_driver <a Mir::Config::Client driver>
#           --config_params <a JSON-encoded file of connection params>
#
#  DESCRIPTION: Connects to the configuration server with the passed params
#  and dumps the configuration section
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Marco Masetti
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/09/2017 11:39:06 AM
#     REVISION: ---
#===============================================================================
use utf8;
use Moose;
use Mir::Config::Client;
use Getopt::Long            qw( GetOptions );
use JSON;
use Data::Printer;


my $config_driver = 'Mongo';
my ( $config_params, $config_params_json ) = ( "", "" );


GetOptions(
    "config_driver=s"   => \$config_driver,
    "config_params=s"   => \$config_params_json
) or die <<EOT;

Usage: $0 
    --config_driver <a Mir::Config::Client driver>
    --config_params <a JSON-encoded file of connection params>

EOT

eval {
    local $/;
    open ( my $fh, '<', $config_params_json );
    my $json_text = <$fh>;
    $config_params = decode_json( $json_text );
    close $fh;
};
if ( $@ ) {
    die <<EOT;

$@

Usage: $0 
    --config_driver <a Mir::Config::Client driver>
    --config_params <a JSON-encoded file of connection params>

EOT
}

print "Config Driver: $config_driver\n";
print "Config Params:\n";
p $config_params;

my $c = Mir::Config::Client->create( 
    driver  => $config_driver,
    params  => $config_params
) or die "Error getting a Mir::Config::Client object\n";

$c->connect() or die "Error connecting to the Config server\n";

my $section = $c->get_section()
    or die "Error getting section\n";

print "Section Configuration:\n";
p $section;

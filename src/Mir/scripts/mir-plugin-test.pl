#===============================================================================
#
#         FILE: mir-plugin-test.pl
#
#        USAGE: ./mir-plugin-test.pl --class <plugin class suffix>
#                                    --config_params_file <a JSON-encoded file of config params>
#                                    --input_params_file <a JSON-encoded file of input params>
#
#  DESCRIPTION: Runs a plugin.
#
#       AUTHOR: Marco Masetti
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 10/20/2016 03:43:20 PM
#     REVISION: ---
#===============================================================================
package PluginHandler;
use Moose;
with 'Mir::R::PluginHandler';

has 'class'         => (is => 'rw', isa => 'Str'     );
has 'config_params' => (is => 'rw', isa => 'HashRef' );
has 'input_params'  => (is => 'rw', isa => 'HashRef' );

sub run_plugin {
    my $self = shift;
    my $plugin = Mir::Plugin->create(
        driver  => $self->class,
        params  => $self->config_params
    ) or die "Error getting a $self->{class} plugin object: $@\n";

    my $out = $plugin->run($self->input_params) 
        or die "Error running plugin $self->{class}: $@\n";

    return $out;
}

package main;
use strict;
use warnings;
use Getopt::Long qw( GetOptions );
use JSON         qw( decode_json );
use Data::Dumper qw( Dumper );
use PluginHandler;

my (
    $class,
    $config_params_file,
    $input_params_file,
) = ( undef, undef, undef, 'JSON' );

GetOptions ( "class=s"      => \$class,
             "config_params_file=s" => \$config_params_file,
             "input_params_file=s"  => \$input_params_file,
) or die <<EOT;

    Usage: $0   --class=<plugin class> 
                --config_params_file=<a plugin JSON-encoded configuration file> 
                --input_params_file=<a plugin JSON-encoded input params file>

EOT

unless ( $class && $config_params_file && $input_params_file ) {

    die <<EOT;

    Usage: $0   --class=<plugin class> 
                --config_params_file=<a plugin JSON-encoded configuration file> 
                --input_params_file=<a plugin JSON-encoded input params file>

EOT
}


die "Configuration file not found or not readable\n"
    unless ( -f $config_params_file );

die "Input params file not found or not readable\n"
    unless ( -f $input_params_file );

my $config_params_text;
{
    undef $/;
    open my $fh, "<:encoding(UTF-8)", $config_params_file;
    $config_params_text = <$fh>;
    close $fh;
}
my $config_params = decode_json( $config_params_text )
    or die "Error getting config params\n";

my $input_params_text;
{
    local $/;
    open my $fh, "<:encoding(UTF-8)", $input_params_file;
    $input_params_text = <$fh>;
    close $fh;
}
my $input_params = decode_json( $input_params_text )
    or die "Error getting input params\n";

my $ph = PluginHandler->new(
    class           => $class,
    config_params   => $config_params,
    input_params    => $input_params
);

my $res = $ph->run_plugin();

print "Plugin $class output:\n";
print Dumper($res);
print "\n";

1;

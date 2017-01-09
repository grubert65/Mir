#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: mir-acq-fetcher.pl
#
#        USAGE: ./mir-acq-fetcher.pl --driver <fetcher driver>
#                                    [--params_file <path to a JSON-encode file of fetcher params>]
#
#  DESCRIPTION: A script to run a single fetcher
#
#       AUTHOR: Marco Masetti (grubert65@gmail.com)
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 08/20/2016 09:53:55 AM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use Getopt::Long  'GetOptions';
use Log::Log4perl ':easy';
use JSON          'from_json';
use Mir::Acq::Fetcher;

Log::Log4perl->easy_init($INFO);

my ($driver, $params_file);
GetOptions( "driver=s"       => \$driver,
            "params_file=s"  => \$params_file
);

if ( $@ || not $driver ) {
    die "Usage: $0 --driver <a fetcher driver> [--params_file <path to a JSON-encoded params file>]\n";
}

my $params = {};
if ( $params_file ) {
    die "Params file doesn't exists or not readable\n"
        unless ( -f $params_file );
    undef $/;
    open my $fh, "<$params_file";
    my $json = <$fh>;
    $params = from_json ( $json, { utf8  => 1 } );
    close $fh;
}

my $f = Mir::Acq::Fetcher->create(
    driver => $driver,
    params => $params
);

$f->fetch();





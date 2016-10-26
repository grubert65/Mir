#!/usr/bin/env perl
use strict;
use warnings;
use JSON;
use Data::Dumper qw( Dumper );

my $file = $ARGV[0] or die "Usage: $0 <a json file to check>\n";
die "file not readable" unless ( -f $file );

local $/;
open my $fh, "<$file";
my $str=<$fh>;
close $fh;

my $a = decode_json( $str );
print Dumper($a)."\n";

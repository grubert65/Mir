use strict;
use warnings;
use YAML qw(LoadFile);
use Data::Printer;

my $file = $ARGV[0] or die "Usage: $0 <a json file to check>\n";
die "file not readable" unless ( -f $file );

my $a = LoadFile( $file );
p $a;


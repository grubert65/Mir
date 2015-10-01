#===============================================================================
#
#         FILE: convert_csv.pl
#
#        USAGE: ./convert_csv_to_json.pl  --file <csv input file> 
#                       --tag <JSON tag> --separator <CSV field separator> 
#                       --output <output file>
#
#  DESCRIPTION: Converts CSV data to JSON structure. Source data must be 
#               formatted as a CSV file, with semi-colon (:) as separator
#
#      OPTIONS: --file <csv input file>     The source file (mandatory)
#               --tag                       JSON tag for output structure 
#                                           (optional)
#               --separator                 CSV field separator (optional. If
#                                           not defined, comma will be used)                
#               --output <outfile>          The output file (optional. If not
#                                           defined, STDOUT will be used)
# REQUIREMENTS: JSON, Getopt::Long
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Andrea Poggi
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 09/30/2015 02:57:13 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use JSON;
use Getopt::Long                    qw( GetOptions );
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );
my $log = Log::Log4perl->get_logger( __PACKAGE__ );

my ($file, $tag, $separator, $output) = (undef, undef, ",", undef);
GetOptions (
    "file=s"        => \$file,
    "tag=s"         => \$tag,
    "separator=s"   => \$separator,
    "output=s"      => \$output,
) or die <<EOT;

Usage: $0 --file <csv input file> --tag <optional JSON tag> --separator <optional CSV field separator> --output <optional output file, STDOUT if not provided>

EOT

die ("CSV file has to be passed via the --file input param\n") unless $file;

my $rows = [];
 
# Get all rows and put them in an array of hashes
$log->debug("Opening $file...");
open my $fh, "<:encoding(utf8)", "$file" or die "$file: $!";
binmode($fh);
my $first_row = 1;
$log->debug("$file correctly opened, processing it...");
while ( my $row = <$fh> ) {
    chomp($row);
    my @cells = split (/$separator/, $row);
    my $label = shift @cells;
    my $index = 0;

    for my $cell (@cells) {
        if ($label =~ /data/i) {
            if ($cell =~ /(\d*)\/(\d*)\/(\d*)/) {
                $cell = $3."-".(sprintf("%02d", $2))."-".(sprintf("%02d", $1))."T00:00:00";
            }
        }
        if ($first_row) {
           push @$rows, { $label => $cell }; 
        } else {
           $rows->[$index++]->{$label} = $cell;
        }
    }
    $first_row = undef;
}
close $fh;

# Convert data to JSON
if (scalar @$rows > 0) {
    $log->debug("$file correctly parsed, found ".(scalar @$rows)." cells");
    my $json = JSON->new->pretty;
    my $encoded_text;
    if (defined $tag) {
        $log->debug("Converting data to JSON using \"$tag\" tag");
        $encoded_text = $json->encode({$tag => $rows});
    } else {
        $log->debug("Converting data to JSON using no tag");
        $encoded_text = $json->encode($rows);
    }
    if (defined $encoded_text) {
        my $handle = *STDOUT;
        if (defined $output) {
            open $handle, "> $output";
        }
        print $handle $encoded_text;
        close $handle;
        $log->debug("Processing of $file finished");
    }
} else {
    $log->error("Something may have gone wrong, $file contains no cells");
}

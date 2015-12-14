#===============================================================================
#
#         FILE: convert_csv.pl
#
#        USAGE: ./convert_csv_to_json.pl  --file <csv input file> 
#                       --tag <JSON tag> --separator <CSV field separator> 
#                       --mapfile <YML mapping file> --output <output file>
#
#  DESCRIPTION: Converts CSV data to JSON structure. Source data must be 
#               formatted as a CSV file. This version currently processes files
#               that contains labels in first column.          
#
#      OPTIONS: --file <csv input file>     The source file (mandatory)
#               --tag                       JSON tag for output structure 
#                                           (optional)
#               --separator                 CSV field separator (optional. If
#                                           not defined, comma will be used)                
#               --mapfile                   YAML map file (optional)
#               --substitutions             YAML substitutions file (optional)
#               --output <outfile>          The output file (optional. If not
#                                           defined, STDOUT will be used)
# REQUIREMENTS: JSON, Getopt::Long, YAML, Log::Log4perl
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
use YAML                            qw( Load LoadFile );
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );
my $log = Log::Log4perl->get_logger( __PACKAGE__ );

my $substitutions;
my ($file, $tag, $separator, $mapfile, $subst_file, $output) = (undef, undef, ",", undef, undef, undef);
GetOptions (
    "file=s"            => \$file,
    "tag=s"             => \$tag,
    "separator=s"       => \$separator,
    "mapfile=s"         => \$mapfile,
    "substitutions=s"   => \$subst_file,
    "output=s"          => \$output,
) or die <<EOT;

Usage: $0 --file <csv input file> --tag <optional JSON tag> --separator <optional CSV field separator> --separator <separator char> --mapfile <mapfile path> --output <optional output file, STDOUT if not provided>

EOT

die ("CSV file has to be passed via the --file input param\n") unless $file;

my $rows = [];
my $item;

# If mapping file was provided, load it
if (defined $mapfile) {
    $log->debug("Mapping file $mapfile was provided, loading it...");
    open FILE_INFO, "< $mapfile" or die "Cannot open mapping file $mapfile";
    read (FILE_INFO, $item, (stat(FILE_INFO))[7]);
    close FILE_INFO;
    $log->debug("Mapping file $mapfile was correctly loaded");
}

# If substitutions file was provided, load its YAML
if ((defined $subst_file) && (stat $subst_file)) {
    $substitutions = LoadFile($subst_file);
}
 
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
            # If mapping was provided, use it
            if (defined $item) {
                my $single_row = $item;
                # Labels in mapping structure are uppercase and with _ instead of spaces
                $label =~ s/\s+/_/g;
                $label = uc $label;
                $single_row =~ s/$label/$cell/g;
                push @$rows, $single_row;
            } else {           
                push @$rows, { $label => $cell }; 
            }
        } else {
            # Change value according to substitions, if provided
            $cell = $substitutions->{$cell} if defined $substitutions->{$cell};
            # If mapping was provided, use it
            if (defined $item) {
                my $single_row = $rows->[$index];
                # Labels in mapping structure are uppercase and with _ instead of spaces
                $label =~ s/\s+/_/g;
                $label = uc $label;
                $single_row =~ s/$label/$cell/g;
                $rows->[$index++] = $single_row;
            } else {
               $rows->[$index++]->{$label} = $cell;
            }
        }
    }
    $first_row = undef;
}
close $fh;

# If mapping was provided, we need to convert YAML code to hashes before encoding to JSON
if (defined $item) {
    for (my $index = 0; $index < scalar @$rows; $index++) {
        my $single_row = $rows->[$index];
        $single_row = Load($single_row);
        $rows->[$index] = $single_row;
    }
}

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


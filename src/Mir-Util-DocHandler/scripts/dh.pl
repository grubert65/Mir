#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  dh_pdf.pl
#
#        USAGE:  ./dh.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Marco Masetti (marco.masetti@softeco.it)
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  04/18/2014 05:48:36 PM
#     REVISION:  ---
#===============================================================================
use strict;
use warnings;
use Mir::Util::DocHandler  ();
use Log::Log4perl          qw( :easy );

Log::Log4perl::easy_init( $DEBUG );

#binmode(STDOUT, ":utf8");

my ($driver, $file) = ($ARGV[0], $ARGV[1]);
die "\nQuesto script estrae il testo da una o tutte le pagine di un documento, \
usando il driver DocHandler passato in input \
(se il driver passato e' pdf2 allora \
converte la pagina in immagine ed usa tesseract per estrarre \
il testo della pagina).\n\nUsage: $0 <driver> < file > [< page number >]" 
    unless ( $driver && $file );
die "File not found or not valid" unless -e "$file";

my $page_num = $ARGV[2];

my $doc = Mir::Util::DocHandler->create( driver => $driver )
    or die "Error getting an obj for driver $driver";

$doc->open_doc( "$file" );
print "\nPages: ".$doc->num_pages. "\n";
if ( $page_num ) {
    die "Page is not a digit!" unless ( $page_num =~ /(\d+)/ );
    my ($text, $conf) = $doc->page_text($page_num);
    print "Page: $page_num\n";
    print "TEXT:\n";
    print "$text\n";
    print "Confidence: $conf\n";
} else {
    for ( my $i=1;$i<= $doc->num_pages;$i++) {
        my ($text, $conf) = $doc->page_text($i);
        print "\nPage: $i\n";
        print "TEXT:\n";
        print "$text\n";
        print "Confidence: $conf\n";
    }
}
$doc->delete_temp_dirs();

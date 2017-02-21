#!/usr/bin/env perl 
use strict;
use warnings;
use Mir::Util::ImageHandler;


my ($pdf_file, $page_num) = @ARGV
    or die "Usage: $0 <a pdf file path> <a page number>\n";

die "Usage: $0 <a pdf file path> <a page number>\n"
    unless ( $pdf_file && defined $page_num );

die "pdf file not readable or does not exists\n"
    unless ( -f $pdf_file );

my $file_root = 'temp';
if ( $pdf_file =~ /(\w*)\.pdf/ ) {
    $file_root = $1;
}



my $o = Mir::Util::ImageHandler->new();

my $images = $o->pdfimages(
    pdf_file    => $pdf_file,
    page_num    => $page_num,
    params      => '-tiff',
    out_root    => "./$file_root"
);

print "Images:\n";
print "$_\n" foreach ( @$images );




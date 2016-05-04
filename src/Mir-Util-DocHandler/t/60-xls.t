use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::xls') };

my $display = 0;
ok ($display =~ /\d{1,}/, "Get display");

foreach my $file ( qw( ./data/Udine3.xls ./data/core.xlsx ) ) {
    diag "\nExtracting text from file $file...\n";
    ok (my $doc = Mir::Util::DocHandler::xls->new(), "new"); 
    ok ($doc->open_doc($file), "open_doc");
    is ($doc->pages(), 1, "pages");
    ok (my ($text,$conf) = $doc->page_text(1, "./data"), "page_text");
    diag "\nTEXT:\n$text\n";
    is ($conf,100, 'confidence ok');
#    ok ($doc->ConvertToPDF('./data/Udine3.pdf', $display), "ConvertToPDF");
#    unlink('./data/Udine3.pdf') if stat('./data/Udine3.pdf');
}
done_testing;

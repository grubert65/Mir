use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::xls') };

my $display = 0;
ok ($display =~ /\d{1,}/, "Get display");

foreach my $file ( qw( ./data/core.xlsx ) ) {
    diag "\nExtracting text from file $file...\n";
    ok (my $doc = Mir::Util::DocHandler::xls->new(), "new"); 
    ok ($doc->open_doc($file), "open_doc");
    is ($doc->get_num_pages(), 1, "get_num_pages");
    ok (my ($text,$conf) = $doc->page_text(1, "./data"), "page_text");
    diag "\nTEXT:\n$text\n";
    is ($conf,100, 'confidence ok');
}
done_testing;

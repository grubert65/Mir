use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::rtf') };

my $display = 0;
ok ($display =~ /\d{1,}/, "Get display");

SKIP: {
    skip "catdoc tool not installed", 4 unless ( `which catdoc` );

    ok (my $doc = Mir::Util::DocHandler::rtf->new(), "new"); 
    ok ($doc->open_doc("./data/rtf_test_file.rtf"), "open_doc");
    ok ($doc->pages(), "pages");
    ok (my($text, $confidence) = $doc->page_text(1, "./data"), "page_text");
    is ( $confidence, 100, "confidence is always 100 for an rtf file...");
    isnt ( $text, undef, "ok, got something...");
    ok ($doc->ConvertToPDF('./data/rtf_test_file.pdf', $display), "ConvertToPDF");
    unlink('./data/rtf_test_file.pdf') if stat('./data/rtf_test_file.pdf');
}

done_testing;

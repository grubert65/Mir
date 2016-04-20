use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::doc') };

my $display = 0;
ok ($display =~ /\d{1,}/, "Get display");

SKIP: {
    skip "catdoc tool not installed", 7 unless ( `which catdoc` );

    ok (my $doc = Mir::Util::DocHandler::doc->new(),         "new"); 
    ok ($doc->open_doc("./data/Lucca.doc"),                  "open_doc");
    ok ($doc->pages(),                                       "pages");
    ok ($doc->page_text(1, "./data"),                        "page_text");
    ok ($doc->ConvertToPDF('./data/Lucca.pdf', $display),    "ConvertToPDF");
    unlink('./data/Lucca.pdf') if stat('./data/Lucca.pdf');
    ok ($doc->open_doc("./data/MassaCarrara.doc"),           "open_doc");
    ok ($doc->pages(),                                       "pages");
    ok ($doc->page_text(1, "./data"),                        "page_text");
}

done_testing;

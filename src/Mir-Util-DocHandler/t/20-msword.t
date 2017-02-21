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
    ok ($doc->open_doc("./data/crossmediaretrieval.doc"),    "open_doc");
    is ($doc->get_num_pages(), undef,                        "get_num_pages");
    ok ($doc->page_text(1, "./data"),                        "page_text");
    ok ($doc->ConvertToPDF('./data/crossmediaretrieval.pdf', $display),"ConvertToPDF");
    ok ( -f './data/crossmediaretrieval.pdf', 'Ok, pdf file exists...' );
    unlink('./data/crossmediaretrieval.pdf') if stat('./data/crossmediaretrieval.pdf');
}

done_testing;

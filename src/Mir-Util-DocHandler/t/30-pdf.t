use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN {
    use_ok( 'Mir::Util::DocHandler::pdf' ) || print "Bail out!\n";
}

diag( "Testing Mir::Util::DocHandler::pdf $Mir::Util::DocHandler::pdf::VERSION, Perl $], $^X" );

ok (my $doc = Mir::Util::DocHandler::pdf->new(
        TEMP_DIR => './data'
        ),                                          "new");
# Open with PDF:API2
ok ($doc->open_doc("./data/FVG.pdf"),                                                                     "open_doc 1");
is ($doc->pages(), 292,                                                                                   "pages 1");
ok ($doc->page_text(71, "./data"),                                                                        "page_text 1");
# Open with CAM::PDF
ok ($doc->open_doc("./data/Trentino.pdf"),                                                                 "open_doc 2");
ok ($doc->pages(),                                                                                         "pages 2");
ok ($doc->page_text(58, "./data"),                                                                         "page_text 2");
# Open with pdfinfo
ok ($doc->open_doc("./data/RegioneAbruzzo.pdf"),                                                           "open_doc 3");
ok ($doc->pages(),                                                                                         "pages 3");
ok ($doc->page_text(105, "./data"),                                                                        "page_text 3");

done_testing;

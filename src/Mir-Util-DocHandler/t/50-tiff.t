use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::tiff') };

ok (my $doc = Mir::Util::DocHandler::tiff->new(),                                                          "new"); 
ok ($doc->open_doc("./data/Udine.tiff"),                                                                   "open_doc");
ok ($doc->pages(),                                                                                         "pages");
ok ($doc->page_text(1, "./data"),                                                                          "page_text");
ok ($doc->open_doc("./data/Udine2.tiff"),                                                                  "open_doc");
ok ($doc->ConvertToPDF('./data/Udine.pdf'),                                                                "ConvertToPDF");
unlink('./data/Udine.pdf') if stat('./data/Udine.pdf');

done_testing;

use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::xls') };

my $display = 0;
ok ($display =~ /\d{1,}/,                                                                           "Get display");

ok (my $doc = Mir::Util::DocHandler::xls->new(),                                                    "new"); 
ok ($doc->open_doc("./data/Udine3.xls"),                                                            "open_doc");
is ($doc->pages(), undef,                                                                           "pages");
is ($doc->page_text(1, "./data"), undef,                                                            "page_text");
ok ($doc->ConvertToPDF('./data/Udine3.pdf', $display),                                              "ConvertToPDF");
unlink('./data/Udine3.pdf') if stat('./data/Udine3.pdf');

done_testing;

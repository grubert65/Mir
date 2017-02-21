use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::docx') };

ok (my $doc = Mir::Util::DocHandler::docx->new(), "new"); 
ok ($doc->open_doc("./data/msword_test_file.docx"), "open_doc");
is ($doc->get_num_pages(), 1, "get_num_pages");
ok (my $text = $doc->page_text(1), "page_text");

done_testing;

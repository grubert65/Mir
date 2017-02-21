use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::html') };

diag( "Testing Mir::Util::DocHandler::html $Mir::Util::DocHandler::html::VERSION, Perl $], $^X" );

ok (my $doc = Mir::Util::DocHandler::html->new(), "new"); 
# moved to Mir::R::Acq::Fetch::Spider where is used...
# ok ($doc->CheckFileType( "./data/perl.org.html" ), "CheckFileType");
ok ($doc->open_doc("./data/perl.org.html"), "open_doc");
ok ($doc->get_num_pages(), "get_num_pages");
ok (my ( $t, $c) = $doc->page_text(1, "./data"), "page_text");
note "Text:";
note $t;
note "Confidence: $c";

done_testing;

use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::html') };

diag( "Testing Mir::Util::DocHandler::pdf $Mir::Util::DocHandler::pdf::VERSION, Perl $], $^X" );

ok (my $doc = Mir::Util::DocHandler::html->new(), "new"); 
ok ($doc->CheckFileType( "./data/perl.org.html" ), "CheckFileType");
ok ($doc->open_doc("./data/perl.org.html"), "open_doc");
ok ($doc->pages(), "pages");
ok (my ( $t, $c) = $doc->page_text(1, "./data"), "page_text");
note "Text:";
note $t;
note "Confidence: $c";

done_testing;

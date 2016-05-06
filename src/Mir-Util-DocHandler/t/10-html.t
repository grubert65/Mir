use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::html') };

diag( "Testing Mir::Util::DocHandler::pdf $Mir::Util::DocHandler::pdf::VERSION, Perl $], $^X" );

ok (my $doc = Mir::Util::DocHandler::html->new(), "new"); 
ok ($doc->CheckFileType( "./data/html file.html" ), "CheckFileType");
ok ($doc->open_doc("./data/Storo.html"), "open_doc");
ok ($doc->pages(), "pages");
ok ($doc->page_text(1, "./data"), "page_text");
ok ($doc->ConvertToPDF('./data/Storo.pdf'), "ConvertToPDF");
ok ($doc->delete_temp_files(), 'delete_temp_files' );
unlink('./data/Storo.pdf') if stat ('./data/Storo.pdf');

done_testing;

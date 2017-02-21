use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN { use_ok('Mir::Util::DocHandler::ppt') };

foreach my $file ( qw( ./data/sample.pptx ) ) {
    diag "\nExtracting text from file $file...\n";
    ok (my $doc = Mir::Util::DocHandler::ppt->new(), "new"); 
    $doc->temp_dir_root('./data/temp');
    ok ($doc->open_doc($file), "open_doc");
    is ($doc->get_num_pages(), 1, "get_num_pages");
    ok (my ($text,$conf) = $doc->page_text(1), "page_text");
    diag "\nTEXT:\n$text\n";
    is ($conf,100, 'confidence ok');
}
done_testing;



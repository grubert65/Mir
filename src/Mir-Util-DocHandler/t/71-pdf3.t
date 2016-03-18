use Test::More;
use File::Path      qw( remove_tree );

binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";

use Log::Log4perl   qw(:easy);
Log::Log4perl->easy_init($DEBUG);

BEGIN { 
    use_ok('Mir::Util::DocHandler');
    use_ok('Mir::Util::DocHandler::pdf3');
}

$ENV{CACHE_DIR} = './data';
remove_tree( './data/pages' ) if (-d './data/pages');
remove_tree( './data/images') if (-d './data/images');

ok (my $doc = Mir::Util::DocHandler->create(driver => 'pdf3'), "new"); 
ok ($doc->open_doc("./data/Piano attività.pdf"), "open_doc");
is ($doc->pages(), 1, "pages");
ok (my ($text,$conf)=$doc->page_text(1), 'page_text');

ok (my $doc2 = Mir::Util::DocHandler->create(driver => 'pdf3'), "new"); 
ok ($doc2->open_doc("./data/Piano attività.pdf"), "open_doc");
is ( ($doc2->page_text(1))[0], $text, "got same text...");

# now tries to extract text from all pages...
ok ($doc->open_doc("./data/Jaae-is2007.pdf"), "open_doc");
ok (my $num_pages = $doc->pages(), 'pages' );
is ( $num_pages, 4, 'got right number of pages');
for( my $num_page=1;$num_page<=$num_pages;$num_page++) {
    ok( ($text,$conf) = $doc->page_text( $num_page ) );
    diag "Confidence on text for page $num_page: $conf";
}

done_testing;


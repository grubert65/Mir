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

$ENV{CACHE_DIR} = './data/temp';
remove_tree( './data/pages' ) if (-d './data/pages');
remove_tree( './data/images') if (-d './data/images');

ok (my $doc = Mir::Util::DocHandler->create(driver => 'pdf3'), "new"); 
$doc->temp_dir_root('./data/temp');
ok ($doc->open_doc("./data/plan.pdf"), "open_doc");
is ($doc->get_num_pages(), 1, "get_num_pages");
ok (my ($text,$conf)=$doc->page_text(1), 'page_text');
ok ($doc->delete_temp_files(), 'delete_temp_files' );

ok (my $doc2 = Mir::Util::DocHandler->create(driver => 'pdf3'), "new"); 
$doc2->temp_dir_root('./data/temp');
ok ($doc2->open_doc("./data/plan.pdf"), "open_doc");
is ( ($doc2->page_text(1))[0], $text, "got same text...");
ok ($doc2->delete_temp_files(), 'delete_temp_files' );

# now tries to extract text from all pages...
ok ($doc->open_doc("./data/Jaae-is2007.pdf"), "open_doc");
ok (my $num_pages = $doc->get_num_pages(), 'get_num_pages' );
is ( $num_pages, 4, 'got right number of pages');
for( my $num_page=1;$num_page<=$num_pages;$num_page++) {
    ok( ($text,$conf) = $doc->page_text( $num_page ) );
    note "TEXT for page $num_page";
    note $text;
    note "Confidence on text for page $num_page: $conf";
}
ok ($doc->delete_temp_files(), 'delete_temp_files' );

done_testing;


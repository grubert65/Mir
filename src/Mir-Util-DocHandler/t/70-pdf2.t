use Test::More;
use File::Path      qw( remove_tree );

# binmode STDOUT, ":encoding(UTF-8)";
# binmode STDERR, ":encoding(UTF-8)";

use Log::Log4perl   qw(:easy);
Log::Log4perl->easy_init($DEBUG);

BEGIN { 
    use_ok('Mir::Util::DocHandler');
    use_ok('Mir::Util::DocHandler::pdf2');
}

$ENV{CACHE_DIR} = './data/temp';
remove_tree( './data/temp/pages' ) if (-d './data/pages');
remove_tree( './data/temp/images') if (-d './data/images');

ok (my $doc  = Mir::Util::DocHandler->create(driver => 'pdf2'), "new"); 
ok (my $doc3 = Mir::Util::DocHandler->create(driver => 'pdf2'), "new"); 

ok ($doc->open_doc("./data/plan.pdf"), "open_doc");
ok ($doc3->open_doc("./data/Jaae-is2007.pdf"), "open_doc");

is ($doc->pages(), 1, "pages");
ok (my $pdf_file = $doc->extractPage( 1 ), "extractPage");
ok (-e $pdf_file, "page file exists");
ok (my $img_file = $doc->_get_image_file( 1 ), '_get_image_file');
ok ($doc->convertToImage( $pdf_file, $img_file ), 'convertToImage');
ok (-e $img_file, "image exists");
SKIP: {
    skip "not yet implemented", 1, unless $doc->can('crop');
    ok (my $cropped_img = $doc->crop( $img_file, {
        left    => 100,
        right   => 2230,
        top     => 1480,
        bottom  => 1790
    }), 'crop image');
    ok(-e $cropped_img, "cropped image exists...");
    note("Image cropped: $cropped_img");
}
ok (my ($text,$conf)=$doc->page_text(1), 'page_text');
ok ( $doc->delete_temp_files(), 'delete_temp_files');

# now tries to extract text from all pages...
ok (my $num_pages = $doc3->pages(), 'pages' );
is ( $num_pages, 4, 'got right number of pages');
for( my $num_page=1;$num_page<=$num_pages;$num_page++) {
    ok( ($text,$conf) = $doc3->page_text( $num_page, 'eng' ) );
    note "Confidence on text for page $num_page: $conf";
    note "TEXT:\n$text\n";
}
ok ( $doc3->delete_temp_files(), 'delete_temp_files');

done_testing ();

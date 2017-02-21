#
#===============================================================================
#
#         FILE: 63-pdf2-utf8-chars.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 10/11/2016 06:22:04 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

# use open qw(:std :utf8);
# binmode STDOUT, ":encoding(UTF-8)";

BEGIN {
    use_ok('Mir::Util::DocHandler');
}

ok (my $doc4 = Mir::Util::DocHandler->create(driver => 'pdf2'), "new"); 
ok ($doc4->temp_dir_root( './data/temp' ), 'setting temp_dir_root...' );
ok ($doc4->open_doc("./data/test_utf8.pdf"), "open_doc");
ok (my $num_pages = $doc4->get_num_pages(), 'get_num_pages' );
is ( $num_pages, 1, 'got right number of pages');
for( my $num_page=1;$num_page<=$num_pages;$num_page++) {
    ok( my ($text,$conf) = $doc4->page_text( $num_page, "ita" ) );
    note "Confidence on text for page $num_page: $conf";
    note "TEXT:\n$text\n";
}
ok ( $doc4->delete_temp_files(), 'delete_temp_files');

done_testing ();

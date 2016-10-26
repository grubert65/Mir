use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

binmode STDOUT, ":encoding(UTF-8)";

BEGIN {
    use_ok( 'Mir::Util::DocHandler::pdf' ) || print "Bail out!\n";
}

diag( "Testing Mir::Util::DocHandler::pdf $Mir::Util::DocHandler::pdf::VERSION, Perl $], $^X" );

ok (my $doc = Mir::Util::DocHandler::pdf->new(TEMP_DIR => './data'), "new");
ok ($doc->open_doc("./data/Jaae-is2007.pdf"), "open_doc");
is ($doc->num_pages(), 4, "num_pages");
my $page_num = 2;
ok (my ($t, $c) = $doc->page_text($page_num, "./data"), "page_text");
note "Page $page_num text:";
note $t;
note "Confidence:";
note $c;
like( $t, qr/When the annotation scheme/ , 'got right text back' );

ok ($doc->open_doc("./data/plan.pdf"), "open_doc");
is ($doc->num_pages(), 1, "num_pages");
ok (($t, $c) = $doc->page_text(1, "./data"), "page_text");
note "Page 1 text:";
note $t;
note "Confidence:";
note $c;

done_testing;

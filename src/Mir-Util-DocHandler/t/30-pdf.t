use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN {
    use_ok( 'Mir::Util::DocHandler::pdf' ) || print "Bail out!\n";
}

diag( "Testing Mir::Util::DocHandler::pdf $Mir::Util::DocHandler::pdf::VERSION, Perl $], $^X" );

ok (my $doc = Mir::Util::DocHandler::pdf->new(TEMP_DIR => './data'), "new");
# Open with PDF:API2
ok ($doc->open_doc("./data/Jaae-is2007.pdf"), "open_doc");
is ($doc->pages(), 4, "pages");
ok (my ($t, $c) = $doc->page_text(1, "./data"), "page_text");
note "Page 1 text:";
note $t;
note "Confidence:";
note $c;

done_testing;

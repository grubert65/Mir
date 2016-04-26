use Test::More;
use File::Path      qw( remove_tree );

binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";

use Log::Log4perl   qw(:easy);
Log::Log4perl->easy_init($DEBUG);

BEGIN { 
    use_ok('Mir::Util::DocHandler');
    use_ok('Mir::Util::DocHandler::txt');
}

remove_tree( './data/pages' ) if (-d './data/pages');
remove_tree( './data/images') if (-d './data/images');

ok (my $doc = Mir::Util::DocHandler->create(driver => 'txt'), "new"); 
ok ($doc->open_doc("./lib/Mir/Util/DocHandler.pm"), "open_doc");
is ($doc->pages(), 1, "pages");
ok (my ($text,$conf)=$doc->page_text(1), 'page_text');
is ($conf, 100, 'OK' );

done_testing;


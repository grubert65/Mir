use strict;
use warnings;

use Test::More;
use Log::Log4perl qw(:easy);

Log::Log4perl->get_logger(__PACKAGE__);

BEGIN {
    use_ok('Mir::Util::DocHandler');
}

ok( my $o = Mir::Util::DocHandler->create( driver => 'image' ), 'create' );
ok( $o->open_doc('data/perl.org.png'), 'open_doc' );
ok( my ( $text, $confidence ) = $o->page_text(), 'page_text' );

done_testing;

use strict;
use warnings;

use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

BEGIN {
    use_ok('Mir::Util::ImageHandler');
}

ok( my $o = Mir::Util::ImageHandler->new(), 'new' );
ok( my $images = $o->pdfimages(
        pdf_file    => './data/Jaae-is2007.pdf',
        page_num    => 2,
        params      => '-png',
        out_root    => './data/temp/foo',
    ), 'pdfimages' );
is( scalar @$images, 1, 'ok, got all images' );
ok( my $num = $o->open( @$images ), 'open' );
is( $num, scalar @$images, 'ok, all images opened' );

done_testing();

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
        page_num    => 1,
        params      => '-png',
        out_root    => './data/temp/foo',
    ), 'pdfimages' );
is( ref $images, 'ARRAY', 'ok, got right data type back' );
is( scalar @$images, 0, 'ok, got right number of images back');

ok( $images = $o->pdfimages(
        pdf_file    => './data/Jaae-is2007.pdf',
        page_num    => 2,
        params      => '-png',
        out_root    => './data/temp/foo',
    ), 'pdfimages' );
ok( -f $images->[0], 'ok, first image file exists' );

done_testing();

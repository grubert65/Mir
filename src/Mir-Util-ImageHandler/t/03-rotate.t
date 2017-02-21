use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Test::More;

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
ok( -f $images->[0], 'ok, first image file exists' );

foreach ( @$images ) {
    ok( $o->open( $_ ), 'new' );
    ok( $o->rotate( "90" ), 'rotate' );
    ok( my $rotated = $o->write(), 'write');
    ok( -f $rotated, 'ok, rotated image file exists' );
     # rotate it again...
     ok( $o->rotate( "90" ), 'rotate' );
     ok( $rotated = $o->write(), 'write');
     ok( -f $rotated, 'ok, rotated image file exists' );
}

ok( $o->delete_all(), 'delete_all_images' );

done_testing();

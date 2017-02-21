#
#===============================================================================
#
#         FILE: 61-get_ocr.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 10/11/2016 03:05:47 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($DEBUG);

BEGIN {
    use_ok('Mir::Util::DocHandler');
}

ok(my $o = Mir::Util::DocHandler->create( driver => 'pdf2' ), 'create' );

ok(my($name, $suffix) = $o->get_name_suffix('file.name.with.dots.suffix'), 'get_name_suffix');
is( $name, 'file.name.with.dots', 'ok');
is( $suffix, 'suffix', 'ok');
ok(my ( $text, $confidence ) = $o->get_ocr( './data/perl.org.png', './data/perl.org', 'eng' ), 'get_ocr' );
ok( $confidence > 60, "Got a decent confidence: $confidence" );
unlink './data/perl.org.txt' if ( -f './data/perl.org.txt' );

done_testing;



#
#===============================================================================
#
#         FILE: 64-pdf2-extractPage.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 10/12/2016 10:51:04 AM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use Log::Log4perl qw(:easy);

use Test::More;

Log::Log4perl->easy_init($DEBUG);
BEGIN{ use_ok('Mir::Util::DocHandler') };

ok( my $o = Mir::Util::DocHandler->create( driver => 'pdf2' ), 'create' );
ok( $o->open_doc( "./data/pdf file (with some weird char).in-it-as % this.pdf" ), 'open_doc' );
ok( my $page = $o->extractPage( 2 ), 'extractPage' );
ok( $o->delete_temp_files(), 'delete_temp_files' );


done_testing;

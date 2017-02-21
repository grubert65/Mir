#
#===============================================================================
#
#         FILE: 02-r-pdf.t
#
#  DESCRIPTION: a test for the Mir::Util::R::PDF role.
#
#===============================================================================

package Mir::Util::DocHandler::PDFTest;
use Moose;
with 'Mir::Util::R::DocHandler', 'Mir::Util::R::PDF';

sub page_text {
    return ('', 100);
}

no Moose;
__PACKAGE__->meta->make_immutable;

package main;

use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Mir::Util::DocHandler') };

ok(my $o = Mir::Util::DocHandler->create( driver => 'PDFTest' ), 'create' );
ok($o->open_doc('./data/Jaae-is2007.pdf'), 'open_doc');
is($o->num_pages, 4, 'Ok, got right number of pages back');
ok($o->delete_temp_dirs(), 'delete_temp_dirs' );

done_testing;

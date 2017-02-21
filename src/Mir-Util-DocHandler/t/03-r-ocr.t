#===============================================================================
#
#         FILE: 03-r-ocr.t
#
#  DESCRIPTION: a test for the Mir::Util::R::OCR role.
#
#===============================================================================
package Mir::Util::DocHandler::OCRTest;
use Moose;
with 'Mir::Util::R::DocHandler', 
     'Mir::Util::R::PDF',
     'Mir::Util::R::OCR';

sub page_text {
    return ('', 100);
}

no Moose;
__PACKAGE__->meta->make_immutable;

package main;
use strict;
use warnings;
use Test::More;
use File::Path qw( make_path remove_tree );
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

BEGIN { use_ok('Mir::Util::DocHandler') };

ok(my $o = Mir::Util::DocHandler->create( driver => 'OCRTest' ), 'create' );
ok($o->open_doc('./data/Jaae-is2007.pdf'), 'open_doc');
is($o->num_pages, 4, 'Ok, got right number of pages back');
make_path( "$o->{temp_dir_root}/text" ) unless ( -d "$o->{temp_dir_root}/text" );
ok($o->lang('eng'), 'setting language...');
ok(my ($t, $c) = $o->get_ocr(
        './data/Jaaeis2007-000.png', 
        "$o->{temp_dir_root}/text/$o->{doc_name}"), 'get_ocr' 
);
ok($o->delete_temp_dirs(), 'delete_temp_dirs' );

done_testing;

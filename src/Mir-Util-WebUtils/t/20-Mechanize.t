use strict;
use warnings;
use Test::More;
use File::Path  qw( rmtree );
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN {
    use_ok( 'Mir::Util::WebUtils::Mechanize', qw(:LINK_OPT) ) || print "Bail out!\n";
}

diag( "Testing Mir::Util::WebUtils::Mechanize $Mir::Util::WebUtils::Mechanize::VERSION, Perl $], $^X" );

rmtree ('./test_data') if (stat ('./test_data'));
mkdir ('./test_data');

ok (my $doc = Mir::Util::WebUtils::Mechanize->new(
        TEMP_DIR => './test_data',
        CACHE_DIR => './test_data/cache',
        CACHE_NAME => 'test_web'
        ),                                          "new");
ok ( $doc->WriteCache('year', '1984'),                                                                 "WriteCache");
ok ( $doc->ReadCache('year'),                                                                          "ReadCache");
ok ( $doc->GotoPage( 'http://www.regione.taa.it/bur/Bollettino_1e2.asp' ),                             "GotoPage");
ok ( $doc->FollowLink('ricerca_it.asp', LINK_URL),                                                     "FollowLink");
my $form = $doc->SelectFormByNumber(0);
ok ($form,                                                                                             "SelectFormByNumber");
ok ( $doc->GetFormData($form, 'provenienza'),                                                          "GetFormData");
ok ( $doc->GetFormValues($form, 'provenienza'),                                                        "GetFormValues");
ok ( $doc->FillForm($form, 'provenienza', 'Bollettino Ufficiale'),                                     "FillForm");
ok ( $doc->SubmitPage(),                                                                               "SubmitPage");
ok ( my $pub_node = $doc->SelectNode('name', 'ris_ricerca'),                                           "SelectNode");
ok ( $doc->SetCurrentNode($pub_node->[0]),                                                             "SetCurrentNode");
ok ( my $desc_node = $doc->SelectRightSibling(),                                                       "SelectDescendant");
my $array = ['one', 'two', 'three', 'four', 'five'];
ok ($doc->GetItemIndex($array, 'four'),                                                                "GetItemIndex");
$form = $doc->SelectFormByNumber(0);
ok ( $doc->SubmitForm($form, 'CONTINUA'),                                                              "SubmitForm");
my $nodes;
ok($nodes = $doc->SelectNode('class', 'competenza_anno'),                                              "SelectNode");
ok($doc->SetCurrentNode($nodes->[0]),                                                                  "SetCurrentNode");
ok ($doc->SelectRightSibling(),                                                                        "SelectRightSibling");
my $file_pattern = [];
push @$file_pattern, '(.+\.pdf$)';
my $files_array = $doc->GetFiles($file_pattern);
ok ($files_array,                                                                                    "GetFiles");

ok ($doc->Decompress('./data/docs.zip', './test_data'),                                                "Decompress");

my $title = "Titolo documento";
my $fields = [
               "Delibera di GIUNTA n.235",
               "",
               "",
               "Data pubblicazione: 23/04/2009 00:00:00",
               "Ufficio: Agricoltura", 
               "Titolo: Approvazione Protocollo d'Intesa e Progetto di destinazione congressuale locale Convention & Visitors Bureau Versilia /Costa Apuana 2009-2010 - Decreto Dirigenziale del Settore Politiche di Sviluppo e di Promozione del Turismo della Regione Toscana n.2435 dell' 08.05.2009",
               "",
               "",
               "Si e' verificato un errore tentando di scaricare seguente file:",
               "http://www.provincia.lucca.it/delibere/documenti/G0293_2009_1.doc"
             ];
ok(my $pdf = $doc->CreatePDF($title, $fields, './test_data/testpdf'),                                  "CreatePDF");

rmtree ('./test_data') if (stat ('./test_data'));
done_testing;

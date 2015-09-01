use strict;
use warnings;
use Test::More;
use File::Path  qw( rmtree );
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $DEBUG );

BEGIN {
    use_ok( 'Mir::Util::WebUtils' ) || print "Bail out!\n";
}

diag( "Testing Mir::Util::WebUtils $Mir::Util::WebUtils::VERSION, Perl $], $^X" );

rmtree ('./test_data') if (stat ('./test_data'));
mkdir ('./test_data');

ok (my $doc = Mir::Util::WebUtils->new(
        TEMP_DIR => './data',
        CACHE_DIR => './test_data/cache',
        CACHE_NAME => 'test_web'
        ),                                          "new");
ok ( $doc->WriteCache('year', '1984'),                                                                 "WriteCache");
ok ( $doc->ReadCache('year'),                                                                          "ReadCache");

my $array = ['one', 'two', 'three', 'four', 'five'];
ok ($doc->GetItemIndex($array, 'four'),                                                                "GetItemIndex");

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

ok($doc->CheckFileType('./data/pdf'),                                                                  "CheckFileType");
ok($doc->CheckFileType('./data/doc'),                                                                  "CheckFileType");
ok($doc->CheckFileType('./data/xls'),                                                                  "CheckFileType");
ok($doc->CheckFileType('./data/tif'),                                                                  "CheckFileType");
ok($doc->CheckFileType('./data/rtf'),                                                                  "CheckFileType");

rmtree ('./test_data') if (stat ('./test_data'));

done_testing;

use strict;
use warnings;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
use Test::More;

BEGIN { use_ok('Mir::Util::DocHandler') };

my $TEMP_DIR = './data/temp';

my %docs_per_driver = (
     'doc'   => {
         './data/crossmediaretrieval.doc' => {
             num_pages   => undef,
             text        => qr/The investigators plan to construct a cross-media information retrieval/i,
             min_conf    => 90
         },
     },
     'docx'  => {
         './data/msword_test_file.docx' => {
             num_pages   => undef,
             text        => qr/This file is for test and validate text extraction from MSWord docx format files/i,
             min_conf    => 90
         },
     },
     'html'   => {
         "./data/html file.html" => {
             num_pages   => 1, # currently no way to detect these...
             text        => qr/File Reference/,
             min_conf    => 90
         },
     },
     'pdf'   => {
         "./data/Jaae-is2007.pdf" => {
             num_pages   => 4,
             text        => qr/The JAAE is a desktop application/i,
             min_conf    => 80
         }
     },
    'pdf2'   => {
        "./data/Jaae-is2007.pdf" => {
            num_pages   => 4,
            text        => qr/The JAAE is a desktop application/i,
            min_conf    => 80
        }
    }
);

foreach my $driver ( keys %docs_per_driver ) {
    note "-------------------- Driver $driver ----------------------";
    ok( my $o = Mir::Util::DocHandler->create( 
            driver => $driver,
            params => {
                temp_dir_root => $TEMP_DIR,
            }
        ), 'create' );

    foreach my $doc ( keys %{ $docs_per_driver{ $driver } } ) {
        note " Document: $doc";
        my $text='';
        ok( $o->open_doc( $doc ), 'open_doc' );
        is( $o->num_pages, $docs_per_driver{$driver}{$doc}{num_pages}, 
                'Got right number of pages back' );
        if ( $o->num_pages ) {
            foreach ( 1 .. $o->num_pages ) {
                ok( my ( $t, $c ) = $o->page_text( $_, $TEMP_DIR ), 'page_text' );
                note "Confidence: $c";
                ok( $c > $docs_per_driver{$driver}{$doc}{min_conf}, 'Confidence is ok...' );
                $text .= $t;
            }
            like( $text, $docs_per_driver{$driver}{$doc}{text}, 'Ok, got right text' );
        } else {
            ok( my ( $t, $c ) = $o->page_text(), 'page_text' );
            note "Confidence: $c";
            ok( $c > $docs_per_driver{$driver}{$doc}{min_conf}, 'Confidence is ok...' );
            like( $t, $docs_per_driver{$driver}{$doc}{text}, 'Ok, got right text' );
        }
        ok( $o->delete_temp_dirs(), 'delete_temp_dirs' );
    }
}

done_testing;

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mir::Util::DocHandler',
    AUTHOR           => q{Andrea Poggi <andrea.poggi@softeco.it>},
    VERSION_FROM     => 'lib/Mir/Util/DocHandler.pm',
    ABSTRACT_FROM    => 'lib/Mir/Util/DocHandler.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Archive::Extract'        => 0,
        'Archive::Zip'            => 0,
        'File::Type'              => 0,
        'Path::Class'             => 0,
        'XML::Simple'             => 0,
        'LEOCHARRE::HTML::Text'   => 0,
        'PDF::API2'               => 0,
        'CAN::PDF'                => 0,
        'Image::OCR::Tesseract'   => 0,
        'Image::Size'             => 0,
        'Imager'                  => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mir-Util-DocHandler-*' },
);

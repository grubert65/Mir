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
        'DirHandle'             => 0,
        'DriverRole'            => 0,
        'Time::HiRes'           => 0,
        'File::Copy'            => 0,
        'File::Basename'        => 0,
        'File::Path'            => 0,
        'File::Type'            => 0,
        'Encode'                => 0,
        'LEOCHARRE::HTML::Text' => 0,
        'PDF::API2'             => 0,
        'CAM::PDF'              => 0,
        'Image::OCR::Tesseract' => 0,
        'Image::Size'           => 0,
        'Imager'                => 0,
        'Moose'                 => 0,
        'Path::Class'           => 0,
        'PDF::Extract'          => 0,
        'XML::Simple'           => 0,


    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mir-Util-DocHandler-*' },
);

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
    EXE_FILES        => [
        'scripts/docx2txt.pl',
    ],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'CAM::PDF'              => 0,
        'Data::UUID'            => 0,
        'DirHandle'             => 0,
        'DriverRole'            => 0,
        'File::Copy'            => 0,
        'File::Basename'        => 0,
        'File::Path'            => 0,
        'File::Type'            => 0,
        'File::Remove'          => 0,
        'Encode'                => 0,
        'LEOCHARRE::HTML::Text' => 0,
        'Log::Log4perl'         => 0,
        'Image::OCR::Tesseract' => 0,
        'Image::Size'           => 0,
        'Imager'                => 0,
        'Imager::File::GIF'     => 0,
        'Imager::File::PNG'     => 0,
        'Imager::File::TIFF'    => 0,
        'Imager::Font'          => 0,
        'Moose'                 => 0,
        'namespace::autoclean'  => 0,
        'Path::Class'           => 0,
        'PDF::API2'             => 0,
        'PDF::Extract'          => 0,
        'Text::Extract::Word'   => 0,
        'Time::HiRes'           => 0,
        'XML::Simple'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mir-Util-DocHandler-*' },
);

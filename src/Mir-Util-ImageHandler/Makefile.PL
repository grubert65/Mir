use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mir::Util::ImageHandler',
    AUTHOR           => q{Marco Masetti <marco.masetti@softeco.it>},
    VERSION_FROM     => 'lib/Mir/Util/ImageHandler.pm',
    ABSTRACT_FROM    => 'lib/Mir/Util/ImageHandler.pm',
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
        'Data::UUID'            => 0,
        'DirHandle'             => 0,
        'File::Basename'        => 0,
        'File::Path'            => 0,
        'Image::Magick'         => 0,
        'Log::Log4perl'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mir-Util-ImageHandler-*' },
);

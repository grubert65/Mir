use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mir::IR',
    AUTHOR           => q{Marco Masetti <marco.masetti@softeco.it>},
    VERSION_FROM     => 'lib/Mir/IR.pm',
    ABSTRACT_FROM    => 'lib/Mir/IR.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    EXE_FILES        => [
        'scripts/mir-ir.pl',
    ],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mir'                       => 0,
        'Mir::Stat'                 => 0,
        'Mir::Acq::Fetcher::FS'     => 0,
        'Mir::Config::Client'       => 0,
        'Mir::Config::Client::JSON' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mir-IR-*' },
);

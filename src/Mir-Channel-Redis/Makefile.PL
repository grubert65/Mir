use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mir::Channel::Redis',
    AUTHOR           => q{Marco Masetti <grubert65@gmail.com>},
    VERSION_FROM     => 'lib/Mir/Channel/Redis.pm',
    ABSTRACT_FROM    => 'lib/Mir/Channel/Redis.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Redis'     => 0,
        'JSON::XS'  => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mir-Channel-Redis-*' },
);

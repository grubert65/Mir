use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mir',
    AUTHOR           => q{Marco Masetti <marco.masetti@softeco.it>},
    VERSION_FROM     => 'lib/Mir.pm',
    ABSTRACT_FROM    => 'lib/Mir.pm',
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
        'Data::GUID'            => 0,
        'DateTime'              => 0,
        'Driver'                => 0,
        'enum'                  => 0,
        'HTTP::Cookies'         => 0,
        'Log::Log4perl'         => 0,
        'Mir::Config::Client'   => 0,
        'Moose'                 => 0,
        'MooseX::Storage'       => 0,
        'Queue::Q'              => 0,
        'WWW::Mechanize'        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mir-*' },
);

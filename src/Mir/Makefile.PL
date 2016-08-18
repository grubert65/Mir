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
    EXE_FILES        => [
        'scripts/mir-acq-scheduler.pl',
        'scripts/mir-acq-processor.pl',
        'scripts/mir-store-update.pl',
        'scripts/queue-check.pl',
        'scripts/dh.pl',
        'scripts/mir-ir.pl',
        'scripts/mir-ir-polling.pl',
        'scripts/mir-ir-search.pl'
    ],
    MIN_PERL_VERSION => 5.006,
    test => {RECURSIVE_TEST_FILES=>1},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Data::Dumper'          => 0,
        'Data::GUID'            => 0,
        'DateTime'              => 0,
        'enum'                  => 0,
        'File::Copy'            => 0,
        'Getopt::Long'          => 0,
        'JSON'                  => 0,
        'HTTP::Cookies'         => 0,
        'HTML::TreeBuilder'     => 0,
        'Log::Log4perl'         => 0,
        'Mir::Config::Client'   => 0,
        'MongoDB'               => 0,
        'Moo'                   => 0,
        'Moose'                 => 0,
        'MooseX::Storage'       => 0,
        'Parallel::ForkManager' => 0,
        'Proc::ProcessTable'    => 0,
        'Queue::Q'              => 0,
        'Redis'                 => 0,
        'Search::Elasticsearch' => 0,
        'TryCatch'              => 0,
        'Try::Tiny'             => 0,
        'WWW::Mechanize'        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mir-*' },
);

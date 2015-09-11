use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mir::Util::WebUtils',
    AUTHOR           => q{Andrea Poggi <andrea.poggi@softeco.it>},
    VERSION_FROM     => 'lib/Mir/Util/WebUtils.pm',
    ABSTRACT_FROM    => 'lib/Mir/Util/WebUtils.pm',
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
        'Cache::FileCache'          => 0,
        'PDF::Create'               => 0,
        'Search::Xapian'            => 0,
        'LWP::Protocol::https'      => 0,
        'Log::Log4perl'             => 0,
        'HTTP::Cookies'             => 0, 
        'Time::HiRes'               => 0,
        'HTML::TreeBuilder'         => 0,
        'HTML::Parser'              => 0,
        'Cache::FileCache'          => 0,
        'Archive::Extract'          => 0,
        'File::Basename'            => 0,
        'Data::Dumper'              => 0,
        'PDF::Create'               => 0,
        'File::Type'                => 0, 
        'File::Copy'                => 0, 
        'File::Path'                => 0,
        'HTML::Entities'            => 0,
        'Mir::Util::DocHandler::pdf'=> 0,
        'namespace::autoclean'      => 0,
        'WWW::Mechanize'            => 0,
        'Time::HiRes'               => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mir-Util-WebUtils-*' },
);

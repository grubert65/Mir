use strict;
use warnings;

use Mir::Config;
use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;
#use YAML qw(LoadFile);
#
#my $config = LoadFile('./config.yml');
#
#my $prefix='';
#if ( $config ) {
#    $prefix = $config->{prefix};
#}

my $app = Mir::Config->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/' );
ok( $res->is_success, '[GET /] successful' );

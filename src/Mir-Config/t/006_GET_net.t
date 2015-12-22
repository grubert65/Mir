use strict;
use warnings;

use Mir::Config;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use YAML qw(LoadFile);

my $prefix='';
my $config = LoadFile('./config.yml');
if ( $config && defined $config->{prefix} ) {
    $prefix = $config->{prefix};
}

my $app = Mir::Config->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $res;
diag"Getting Mir::Config server version...";
my $path="$prefix/version";
diag "Path: $path";
$res  = $test->request( GET $path );
ok( $res->is_success, "[GET $path] successful" );
if ($res->is_success ) {
    diag $res->content;
}

#$path="$prefix/net/RBS/";
#diag "Path: $path";
#$res  = $test->request( GET $path );
#ok( $res->is_success, "[GET $path] successful" );

$path="$prefix/net/RBS/rbs";
diag "Path: $path";
$res  = $test->request( GET $path );
ok( $res->is_success, "[GET $path] successful" );
if ( $res->is_success ) {
    diag "GOT response:";
    diag $res->content;
}

done_testing;



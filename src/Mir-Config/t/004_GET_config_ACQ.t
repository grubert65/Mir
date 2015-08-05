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

diag"Getting the profile for the ACQ component...";
$path="$prefix/config/ACQ/";
diag "Path: $path";
$res  = $test->request( GET $path );
ok( $res->is_success, "[GET $path] successful" );

diag"Getting a resource of the ACQ component...";
$path="$prefix/config/ACQ/fetchers";
diag "Path: $path";
$res  = $test->request( GET $path );
ok( $res->is_success, "[GET $path] successful" );
if ( $res->is_success ) {
    diag "GOT response:";
    diag $res->content;
}

diag"Getting all profiles in the config section...";
$path="$prefix/profile/config";
diag "Path: $path";
$res  = $test->request( GET $path );
ok( $res->is_success, "[GET $path] successful" );
if ( $res->is_success ) {
    diag "GOT response:";
    diag $res->content;
} else {
    diag "Response:";
    diag $res->status_line;
}

done_testing;

use strict;
use warnings;

use Mir::Config;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use YAML qw(LoadFile);

SKIP: {
    skip "index route not meaningful...", 2;

    my $config = LoadFile('./config.yml');
    
    my $prefix='';
    if ( $config ) {
        $prefix = $config->{prefix};
    }
    
    my $app = Mir::Config->to_app;
    is( ref $app, 'CODE', 'Got app' );
    
    my $test = Plack::Test->create($app);
    my $res  = $test->request( GET "$prefix/" );
    ok( $res->is_success, "[GET $prefix/] successful" );
}
done_testing;

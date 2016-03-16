use strict;
use warnings;

use Test::More;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use_ok( 'Mir::Store' );
SKIP: {
    skip "Mir::Store::MongoDB not found, skipping...", 6 unless require_ok('Mir::Store::MongoDB');
    ok( my $o = Mir::Store->create(
            driver => 'MongoDB',
            params => {
                "key_attr"  => "id",
                "host"      => "localhost",
                "database"  => "MIR",
                "collection"=> "Foo"
            }
    ), 'create a store obj to handle docs' );
    ok( $o->connect(), 'connect' );
    ok( $o->drop(), 'drop' );
    is( $o->find_by_id('1'), undef, 'doc with id 1 not found');
    ok( $o->insert({ id => '1', foo => 'bar' }), 'insert doc with id 1');
    ok( my $doc = $o->find_by_id('1'), 'doc with id 1 not found');
    is( $o->count(), 1, 'count' );
}

done_testing




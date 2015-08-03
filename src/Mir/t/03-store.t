use strict;
use warnings;

use Test::More;

use_ok( 'Mir::Store' );
SKIP: {
    skip "Mir::Store::Doc::Test not found, skipping...", 6 unless eval { require "Mir::Store::Doc::Test" };
    ok( my $o = Mir::Store->create(driver => 'Doc::Test'), 'create a store obj to handle docs' );
    ok( $o->connect(), 'connect' );
    ok( $o->delete_all_docs(), 'delete_all_docs' );
    is( $o->find_by_id('1'), undef, 'doc with id 1 not found');
    ok( $o->insert({ id => '1', foo => 'bar' }), 'insert doc with id 1');
    ok( my $doc = $o->find_by_id('1'), 'doc with id 1 not found');
}

done_testing




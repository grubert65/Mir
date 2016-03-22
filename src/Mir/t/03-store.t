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

    my $doc = {
        id  => 1,
        foo => 'bar',
    };

    ok( $o->connect(), 'connect' );
    ok( $o->connect(), 'should just get the collection obj from cache...' );
    ok( $o->drop(), 'drop' );
    is( $o->find_by_id(1), undef, 'doc with id 1 not found');
    ok( $o->insert( $doc ), 'insert doc with id 1');
    ok( my $doc1 = $o->find_by_id(1), 'doc with id 1 found');
    delete $doc1->{_id}; # get rid of MongoDB id...
    is_deeply( $doc, $doc1, 'Got right data back...');
    is( $o->count(), 1, 'count' );
    $doc1->{foo}='baz';
    ok( $o->update( $doc1 ), 'update' );
    ok( my $doc2 = $o->find_by_id(1), 'doc with id 1 found');
    delete $doc2->{_id}; # get rid of MongoDB id...
    is_deeply( $doc2, $doc1, 'Got right data back...');

}

done_testing




use strict;
use Mir::Doc;

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

    my $doc = Mir::Doc->new({id => 1});

    ok( $o->connect(), 'connect' );
    ok( $o->connect(), 'should just get the collection obj from cache...' );
    ok( $o->drop(), 'drop' );
    is( $o->count(), 0, 'count' );
    ok( !$o->update( {'_id' => $doc->{_id} }, {'$set' => {'likes' => 'reading'}} ), 'update should fail, no doc to update...' );
    is( $o->find_by_id(1), undef, 'doc with id 1 not found');
    is( $o->get_new_doc('mark_as_indexing' => 1), undef, 'No new doc found...');
    ok( $o->insert( $doc ), 'insert doc with id 1');
    ok( my $doc1 = $o->find_by_id(1), 'doc with id 1 found');
    delete $doc1->{_id}; # get rid of MongoDB id...
    is_deeply( $doc, $doc1, 'Got right data back...');
    is( $o->count(), 1, 'count' );
    ok( my $doc2 = $o->get_new_doc('mark_as_indexing'=>1), 'get_new_doc');
    ok( my $doc3 = $o->find_by_id(1), 'doc with id 1 found');
    is( $doc3->{status}, Mir::Doc::INDEXING, 'status ok');
    ok( !$o->get_new_doc('mark_as_indexing'=>1), 'No new doc anymore...');
    ok( $o->update( { '_id' => $doc3->{_id} }, {'$set' => {'status' => Mir::Doc::INDEXED}} ), 'update' );
    is( $o->count({status => Mir::Doc::INDEXED}), 1, "1 doc indexed");
    $doc3->{status} = Mir::Doc::INDEXED;
    ok( $doc2 = $o->find_by_id(1), 'doc with id 1 found');
    ok( my $doc_cursor = $o->find(), 'find' );
    is( scalar ( $doc_cursor->all ), 1, 'got right number of docs');
    is_deeply( $doc2, $doc3, 'Got right data back...');
}

done_testing




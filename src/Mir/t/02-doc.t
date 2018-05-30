use strict;
use warnings;
use Test::More;
use Mir::Doc;

ok(my $o = Mir::Doc->new(), 'new' );
is( $o->status, Mir::Doc::NEW, 'status ok');

ok(my $h = $o->pack(), 'pack');
is(ref $h, 'HASH', 'got right data type back');
is( $h->{status}, Mir::Doc::NEW, 'status ok');
ok(my $o2 = Mir::Doc->unpack($h), 'unpack' );
is( $o2->status, Mir::Doc::NEW, 'status ok');

ok( my $json_str = $o2->freeze(), 'freeze' );
ok( my $o3 = Mir::Doc->thaw( $json_str ), 'thaw' );
is( $o3->status, Mir::Doc::NEW, 'status ok');


done_testing;

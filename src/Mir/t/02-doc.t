use strict;
use warnings;
use Test::More;
use Mir::Doc;

ok(my $o = Mir::Doc->new(), 'new' );
is( $o->status, Mir::Doc::NEW, 'status ok');

done_testing;

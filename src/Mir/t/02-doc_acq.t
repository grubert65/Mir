use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Mir::Doc::Acq' );
}

ok(my $o = Mir::Doc::Acq->new(), 'new' );
is( $o->status, 0, 'status ok');
is( $o->tag, 'ACQ', 'tag ok');

done_testing;


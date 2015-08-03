use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Mir::Doc' );
}

ok(my $o = Mir::Doc->new(), 'new' );
is( $o->status, 0, 'status ok');

done_testing;

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Mir::Plugin::IR::ComputeTermsFrequency');
}

my $text =<<EOT;

Perl rocks! Nothing is better then coding in perl

EOT

my $query = "perl";

ok(my $o = Mir::Plugin::IR::ComputeTermsFrequency->new(), 'new');
ok(my $r = $o->compute_term_frequency( $text, $query, 'en', 0 ), 'compute_term_frequency');
is(scalar @$r, 2, 'got right data back');

$query = "better then";
ok($r = $o->compute_term_frequency( $text, $query, 'en', 0 ), 'compute_term_frequency');
is(scalar @$r, 1, 'got right data back');

done_testing;

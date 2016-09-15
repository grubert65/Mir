#
#===============================================================================
#
#         FILE: 01-plugin.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 09/15/2016 01:30:20 PM
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Mir::Plugin' );
}

ok(my $p = Mir::Plugin->create(driver => 'Foo'), 'create a plugin...');
ok(my $o = $p->run(), 'run it');
is($o->{status},1,'got right data back');
done_testing;

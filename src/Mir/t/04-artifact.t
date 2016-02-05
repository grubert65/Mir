use strict;
use warnings;

use Test::More; 

use_ok('Artifact');

done_testing;

package Artifact;
use Moose;
with 'Mir::R::Doc', 'Mir::R::Doc::Web', 'Mir::R::Doc::Artifact';

1;



our $VERSION = '0.01';

package Mir::Util::DocHandler;
use Moose;
use namespace::autoclean;

with 'DriverRole', 'Mir::Util::R::DocHandler';

1;

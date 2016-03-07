package Mir::Doc;
require Exporter;
use Moose;
use namespace::autoclean;
with 'DriverRole', 'Mir::R::Doc';

use vars qw(@EXPORT_OK %EXPORT_TAGS);

use constant NEW        => 0;
use constant INDEXED    => 1;
use constant DELETED    => 2;

@EXPORT_OK = qw( NEW INDEXED DELETED );
%EXPORT_TAGS = (statuses => [qw( NEW INDEXED DELETED )] );

# doc status
has 'status' => ( 
    is      => 'rw',
    isa     => 'Int',
    default => sub { NEW },
);

1;

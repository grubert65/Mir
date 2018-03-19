package Mir::Doc;
require Exporter;
use Moose;
use namespace::autoclean;
with 'DriverRole', 'Mir::R::Doc';

use vars qw(@EXPORT_OK %EXPORT_TAGS);

use constant NEW            => 0;   # default status for any new document
use constant INDEXED        => 1;   # document properly indexed
use constant DELETED        => 2;   # document deleted
use constant INDEXING       => 3;   # document reserved by a mir-ir process for indexing
use constant IDX_FAILED     => 4;   # indexing failed for some reason
use constant INVALID_SUFFIX => 5;   # doc suffix not handled
use constant NO_TEXT        => 6;   # no text found
use constant CONF_TOO_LOW   => 7;   # confidence below threashold

@EXPORT_OK = qw( 
    NEW 
    INDEXED 
    DELETED 
    INDEXING 
    IDX_FAILED 
    INVALID_SUFFIX 
    NO_TEXT 
    CONF_TOO_LOW 
);

%EXPORT_TAGS = (status => [qw( 
        NEW 
        INDEXED 
        DELETED 
        INDEXING 
        IDX_FAILED 
        INVALID_SUFFIX 
        NO_TEXT 
        CONF_TOO_LOW 
)] );

# doc status
has 'status' => ( 
    is      => 'rw',
    isa     => 'Int',
    default => sub { NEW },
);

1;

package Mir::Doc;
use Moose;
use namespace::autoclean;

with 'DriverRole', 'Mir::R::Doc';

# doc status
use enum qw( 
    NEW 
    INDEXED
    DELETED
);

1;

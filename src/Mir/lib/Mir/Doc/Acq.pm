package Mir::Doc::Acq;
use Moose;
use namespace::autoclean;

extends 'Mir::Doc';

has 'tag'  => ( is => 'rw', default => 'ACQ' );

1;

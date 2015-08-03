package Mir::Doc::WU;
use Moose;
use MooseX::Storage;
use namespace::autoclean;

extends 'Mir::Doc';

has 'current_observation' => ( is => 'rw', isa => 'HashRef' );

with Storage(
        io => [ 'MongoDB' => {
             key_attr   => 'id',
             database   => 'MIR',
             collection => 'WU',
        }]
);

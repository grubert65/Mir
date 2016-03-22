package Mir::R::Store;

use Moose::Role;
use namespace::autoclean;
use MongoDB;
use Log::Log4perl;
use Try::Tiny;

requires 'connect';
requires 'find_by_id';
requires 'insert';
requires 'update';
requires 'drop';

1;

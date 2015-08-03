package Mir::R::Acq::Fetch;
#============================================================= -*-perl-*-

=head1 NAME

Mir::R::Acq::Fetch - Ruolo base per ogni processore

=head1 VERSION

0.01

=cut

#HISTORY
# 0.01 | 21.05.2015 | draft
our $VERSION='0.01';

=head1 SYNOPSIS

Ruolo base per ogni processore

    package Mir::Acq::Processor;
    use Moose;
    with 'Mir::R::Acq::Fetch';

Please take care at role order if you like to chain them, as in:

    use Moose;
    with 'Mir::R::ACQ::Fetch', 
         'Mir::R::ACQ::Extract';

=head1 DESCRIPTION

Stabilisce cosa un processore e' capace di fare ma lascia l'implementazione
a ruoli/classi che lo consumano.

Then each fetch subroutine should at least evaluate:

    $self->ret              # return code (1/0)
    $self->docs             # profili documenti acquisiti
    $self->errors           # arrayref of critical errors 

=head1 AUTHOR

Marco Masetti (marco.masetti @ softeco.it )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SUBROUTINES/METHODS

=cut

#========================================================================
use Moose::Role;
use namespace::autoclean;
use Log::Log4perl;

has 'ret'       => ( is => 'rw', isa => 'Int' );
has 'docs'      => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'errors'    => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

has 'log' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Log::Log4perl->get_logger( __PACKAGE__ ); },
);

has 'params' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { return {} },
);

requires 'get_docs';

#=============================================================

=head2 fetch

=head3 INPUT

=head3 OUTPUT

1/undef in case of errors.

=head3 DESCRIPTION

Workflow:
- per ogni doc in $self->docs:
     - scarica documenti e store doc

=cut

#=============================================================
sub fetch {
    my $self = shift;
}

1;

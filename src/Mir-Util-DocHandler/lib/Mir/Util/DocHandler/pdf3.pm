package Mir::Util::DocHandler::pdf3;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Util::DocHandler::pdf3 - Tries to combine the best of pdf and pdf2

=head1 VERSION

0.01

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

    use Mir::Util::DocHandler;

    my $o = Mir::Util::DocHandler->create( driver => 'pdf3' );

    # see Mir::Util::R::DocHandler for details on the 
    # implemented interface


=head1 DESCRIPTION

This module tries to extract pdf text first using the pdf driver (faster),
and then, if confidence doesn't exceed a threashold, using the pdf2 driver
(slower but more robust)


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
use Moose;
use namespace::autoclean;
use Mir::Util::DocHandler;
use File::Path qw(remove_tree);

has 'confidence_threashold' => ( is => 'rw', isa => 'Int', default => 40 );
has 'temp_dir_root' => ( is => 'rw', isa => 'Str' );

has 'pdf1_dh' => ( 
    is  => 'ro', 
    isa => 'Mir::Util::DocHandler::pdf', 
    default => sub { return Mir::Util::DocHandler->create( driver => 'pdf' ) } 
);

has 'pdf2_dh' => ( 
    is  => 'ro', 
    isa => 'Mir::Util::DocHandler::pdf2', 
    default => sub { return Mir::Util::DocHandler->create( driver => 'pdf2' ) } 
);

sub open_doc {
    my ($self, $doc) = @_;
    foreach ( ( qw( pdf1_dh pdf2_dh ) ) ) {
        $self->{$_}->temp_dir_root( $self->temp_dir_root );
        $self->{$_}->open_doc( $doc );
    }
    return 1;
}

sub get_num_pages {
    my $self = shift;
    return $self->pdf1_dh->get_num_pages();
}

sub page_text {
    my ($self, $page) = @_;

    my @drivers = qw( pdf1_dh pdf2_dh );

    my ($t_best, $c_max, $index) = ("", 0, 0);

    while( ( $index < scalar @drivers ) && ( $c_max < $self->confidence_threashold ) ) {
        my $driver = $drivers[ $index ];
        my ( $t, $c ) = $self->$driver->page_text( $page );
        if ( $t && ( $c > $c_max ) ) {
            $c_max = $c;
            $t_best= $t;
        }
        $index++;
    }

    return ( $t_best, $c_max );
}

sub delete_temp_files {
    my $self = shift;

    remove_tree( $self->temp_dir_root ) if ( -d $self->temp_dir_root );
}

1;

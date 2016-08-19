package Mir::Config::Client::JSON;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Config::Client::JSON - implements the Mir::R::Config role 
on a JSON encoded configuration file.

=head1 VERSION

0.01

=cut

use vars qw( $VERSION );
$VERSION='0.01';

=head1 SYNOPSIS

    use Mir::Config::Client;
    my $o = Mir::Config::Client->create( 
        driver => 'JSON',
        params => {
            path => '...'
        });

    # opens and parses the file...
    $o->connect() 
        or die "Error getting a Mir::Config::Client::JSON obj\n";

    # refer to L<Mir::R::Config> role for detailed API documentation

=head1 DESCRIPTION

A class that handles a Mir::Config section stored on a JSON file.
By default a configuration file can hold the description of a single section.

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
use JSON;
use Log::Log4perl;
use TryCatch;
with 'Mir::R::Config';

has 'path' => ( is => 'rw', isa => 'Str' );

has 'config' => ( is => 'rw', isa => 'ArrayRef' );

has 'log' => (
    is => 'ro',
    isa => 'Log::Log4perl::Logger',
    default => sub {
        return Log::Log4perl->get_logger( __PACKAGE__ );
    }
);

#=============================================================

=head2 connect

=head3 INPUT

=head3 OUTPUT

1 in case of success otherwise undef

=head3 DESCRIPTION

Tries to open the file and parse the content...

=cut

#=============================================================
sub connect {
    my  $self = shift;

    try {
        die "No path configured!\n"     unless ( $self->path );
        die "No config file found!\n"   unless ( -f $self->path );
        my $json;
        {
            local $/;
            my $fh;
            open $fh, "<$self->{path}";
            $json = <$fh>;
            close $fh;
        }
        $self->config( decode_json ( $json ) );
    } catch ( $err ) {
        $self->log->error($err);
        return undef;
    };

    return $self;
}

#=============================================================

=head2 get_section

=head3 INPUT

    $section : the section label.

=head3 OUTPUT

=head3 DESCRIPTION

Returns the complete content of the configuration file, as by
default there is a configuration file for each section.

=cut

#=============================================================
sub get_section {
    my ( $self, $section ) = @_;

    return $self->config;
}

#=============================================================

=head2 get_key

=head3 INPUT

    $keys:  An hashref with a list of key/value pairs
    $attrs: An hashref with the list of attributes to have back( {a=>1,b=>1,...} )

=head3 OUTPUT

An arrayref.

=head3 DESCRIPTION

Looks in the config data for all structures matching the list of keys passed.
Returns only the selected attributes.
Note: currently $keys and $attrs must be first level keys.

=cut

#=============================================================
sub get_key {
    my ( $self, $keys, $attrs ) = @_;

    my $out_params = [];
    foreach my $module ( @{ $self->config } ) {
        my $found = 0;
        foreach my $key ( keys %$keys ) {
            if (( exists $module->{ $key } )&& 
                ( $keys->{$key} eq $module->{ $key } ) )  {
                $found++;
            }
        }
        if ( $found == scalar keys ( %$keys ) ) {
            my $doc = {};
            foreach my $attr ( keys %$attrs ) {
                $doc->{ $attr } = $module->{ $attr }  
                    if ( exists $module->{ $attr } );
            }
            push @$out_params, $doc;
        }
    }

    return $out_params;
}

1; # End of Mir::Config::Client::Mongo

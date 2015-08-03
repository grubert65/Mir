#!/usr/bin/env perl 

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#  Application Documentation
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

=head1 NAME

mir-acq - Mir script that handles acqusition.

=head1 VERSION

0.01

=cut

our $VERSION='0.01';

=head1 USAGE

Add script launch in crontab.

Params:

    --config: path to the global Mir config file
    --campaign: campaign tag to follow


=head1 DESCRIPTION

Questo script si occupa di lanciare l'esecuzione di tutti i processori configurati
per una campagna.

=head1 CONFIGURATION AND ENVIRONMENT

Configuration section Mir.acq in main Mir config data store.

=head1 AUTHOR

Marco Masetti


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti. All rights reserved.

Followed by whatever licence you wish to release it under.
For Perl code that is often just:

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

use strict;
use warnings;
use utf8;
use Getopt::Long;
use Mir                 ();
use Mir::Store          ();
use Mir::Acq            ();
use Mir::Acq::Schema    ();

my $config_file = './mir.yml';
my @campaigns;
my $campaign_from_cmd;
my $processor_driver = 'FS';

GetOptions (
    "config=s"  => \$config_file,
    "campaign=s"=> \$campaign_from_cmd,
) or die("Error in command line arguments\n");

# Workflow
#
#- l'acquisizione e' schedulata via cron
#- Il processo mir-acq parte (mir-acq --config <config-file> --campaign <campaign tag>...<other params...>)
#-------------------------------------------
#- inizializza i vari oggetti
#-------------------------------------------
die "Config file not readable\n" unless ( -e $config_file );
my $config = Load( $config_file );

my $store = Mir::Store->new(...);

#-------------------------------------------
# recupera un session id per identificare 
# univocamente l'acquisizione
# (il session_id viene conservato anche dall'oggetto Store...)
#-------------------------------------------
my $session_id = $store->get_session_id();

#-------------------------------------------
#- recupera la o le campagne di acquisizione
#-------------------------------------------
if ( $campaign_from_cmd ) {
    push @campaigns, $campaign_from_cmd;
} else {
    push @campaigns, $config->{Mir}->{Acq}->{campaigns};
}

my $acq_schema = Mir::Acq::Schema->connect( @{ $config->{Mir}->{Acq}->{Schema} } )
    or die "Error connecting to the Acq schema: $@";

foreach my $campaign ( @campaigns ) {
    # recupera la lista dei processori (il driver da usare e' configurato, vedi <gestione processori>)
    # qui potremmo applicare prima il ruolo opportuno alla classe e poi 
    # chiamare il metodo...
    my @processors = Mir::Acq.....->get_processors();

    foreach my $processor ( @processors ) {
    #    - fork e istanzia processore $p in thread (vedi Parallel::ForkManager)
    #    - $p->fetch() (store docs/errors su MongoDB)
    }
}

#- notifica errori
my $fetch_errors = $store->get_errors();

__DATA__
Mir:
    Acq:
        campaigns:
            - foo
            - bar
            - baz
        processor:
            driver: FS

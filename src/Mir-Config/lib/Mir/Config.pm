package Mir::Config;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Config - Mir server per la gestione della configurazione dei
componenti Mir

=head1 VERSION

0.1

=head1 DESCRIPTION

Il componente permette di centralizzare la configurazione del sistema 
e dei singoli componenti del sistema. 
La configurazione e' organizzata in sezioni.

l'accesso ai parametri di configurazione e' via chiamate REST.

Routes:
Le route sono automaticamente definite impostando le risorse gestite via REST

Inoltre sono definite le seguenti route:

    GET /version                => riporta json {"version":"x.xx"} (versione corrente del componente)
    GET /v1/<section>           => ritorna json profilo intera sezione
    GET /v1/system/<component>  => riporta json profilo componente

=head1 CONFIGURATION AND ENVIRONMENT

La configurazione di default e' in config.yml

=head1 AUTHOR

Marco Masetti (marco.masetti @ softeco.it )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

#========================================================================
use Dancer2;
use Dancer2::Plugin::REST   ();
use Dancer2::Plugin::Ajax   ();
use MongoDB                 ();

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/version' => sub {
    return ( { version => $VERSION } );
};

get '/appname' => sub {
    return { appname => config->{appname} };
};

#=============================================================

=head2 GET /id/:section/:id - ritorna un doc con id :id dalla sezione 
            config->{store}->{sections}->{:section}

=head3 INPUT

    $section    : sezione della configurazione
    $id         : id univoco del documento (profilo) da recuperare

=head3 OUTPUT

=head3 DESCRIPTION

# TODO : dovrebbe essere /byId o qualcosa di simile...
Recupera il documento con Mongo ID passato dalla sezione passata
(oppure tutti i documenti della sezione se id non passato...)

=cut

#=============================================================
get '/id/:section/:id' => sub {
    $DB::single=1;
    debug "/id...";
    my $section = params->{section};
    debug "Section: $section";
    my $id;
    $id = param('id') if ( defined param('id') );
    my $collection = config->{store}->{sections}->{ $section }
        or die "Error: no section $section configured";
    my $host    = config->{store}->{host};
    my $port    = config->{store}->{port};
    my $db      = config->{store}->{database};
    debug "HOST: $host, PORT: $port, DB: $db";
    debug "Collection: $collection";
    my $client     = MongoDB::MongoClient->new(host => $host, port => $port);
    my $database   = $client->get_database( $db );
    my $ch = $database->get_collection( $collection );
    my $data;
    if ( defined $id ) {
        $data = $ch->find_one({ _id => $id });
    } else {
        $data = $ch->find();
    }

    return $data;
};

#=============================================================

=head2 GET /key/:section/:key/:value - ritorna un doc  dalla sezione 
            config->{store}->{sections}->{:section} con valore :value
            per la chiave :key

=head3 INPUT

    $section    : sezione della configurazione
    $key        : campo da usare come chiave univoca 
    $value      : valore del campo chiave

=head3 OUTPUT

=head3 DESCRIPTION

Recupera il documento puntato dalla chiave univoca dalla sezione passata

=cut

#=============================================================
get '/key/:section/:key/:value' => sub {
    my $section = param('section');
    my $key     = param('key');
    my $value   = param('value');

    die "key or value not passed"
        unless ( $key && $value );

    my $collection = config->{store}->{sections}->{ $section }
        or die "Error: no section $section configured";

    my $host   = config->{store}->{host};
    my $port   = config->{store}->{port};
    my $db     = config->{store}->{database}
        or die ("Database not set");

    my $client = MongoDB::MongoClient->new(host => $host, port => $port);
    my $database = $client->get_database( $db );
    my $ch = $database->get_collection( $collection );
    my $data;
    $data = $ch->find_one({ $key => $value });

    return $data;
};

true;

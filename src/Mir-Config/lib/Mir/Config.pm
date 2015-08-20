package Mir::Config;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Config - a small server to serve generic configuration sections
for the Mir system.

=head1 VERSION

0.1

=head1 DESCRIPTION

Provides a REST interface to configuration sections. it is fairly
generic, handling configuration sections (handled as Mongo collections)
transparently.

Inoltre sono definite le seguenti route:
The routes defined are:

  GET /<app>/version                             :returns a json string as {"version":"x.xx"} (current component version)
TODO  GET /<app>/<v>/<section>/[<item>]/[<resource>] :returns the given item resource belonging to the section or the
                                                  entire section if no item specified

=head1 CONFIGURATION AND ENVIRONMENT

As any Dancer2 app configuration in config.yml and environment defaults to development

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
use TryCatch;
use MongoDB                 ();
use Data::Dumper            qw( Dumper );

use vars qw( 
    $VERSION
    $client
    $database
    $cursor
);

$VERSION = '0.1';

# TODO : defaults needed as in test env config is not loaded (why ?)...
my $host   = config->{store}->{host}     || 'localhost';
my $port   = config->{store}->{port}     || 27017;
my $db     = config->{store}->{database} || 'MIR';

debug "Host:     $host";
debug "Port:     $port";
debug "Database: $db";

$client = MongoDB::MongoClient->new(host => $host, port => $port);
$database = $client->get_database( $db );

# the prefix cmd can be used to set the /<app>/ prefix
# to any query.
my $prefix = config->{prefix};
if ( defined $prefix ) {
    debug "NOTE: USING PREFIX $prefix";
    prefix $prefix;
}

#=============================================================

=head2 /

=head3 DESCRIPTION

Returns a json-encoded string with all collections documents.

=cut

#=============================================================
get '/' => sub {

    my $data = {};

    try {
        my @collections = $database->collection_names;
        foreach my $collection ( @collections ) {
            my $cursor = $database->get_collection( $collection )->find();
            if ( $cursor->count() ) {
                $data->{ $collection } = [ $cursor->all() ];
            }
        }
    } catch {
        error "Error getting config database content";
    }

    debug "Complete Config database:";
    debug Dumper $data;
    return $data;
};

get '/version' => sub {
    return ( { version => $VERSION } );
};

get '/appname' => sub {
    return { appname => config->{appname} };
};

get '/profile/:collection' => sub {
    my $collection = params->{collection};
    debug "Collection: $collection";
    $cursor = eval{ $database->get_collection( param('collection') )->find(); };
    if ( $@ ) {
        error "Error getting entire profile for collection $collection";
        status 500;
    }
    my $data;
    if ( $cursor->count() ) {
        $data = [ $cursor->all() ];
    }
    debug "Profile for section $collection:";
    debug Dumper $data;
    return $data;
};

#=============================================================

=head2 GET /:collection/:tag?/:resource?

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

=cut

#=============================================================
get '/:collection/:tag?/:resource?' => sub {
    my $collection = params->{collection};
    die "Error: no section $collection configured" unless $collection;
    $collection = config->{store}->{sections}->{ $collection } || $collection;
    debug "Section: $collection";
    my $ch = $database->get_collection( $collection );

    my $tag      = params->{tag};
    my $resource = params->{resource}; debug "Resource:$resource" if ( defined $resource );
    my $data;
    if ( defined $tag ) {
        debug "Getting profile for tag $tag...";
        if (defined $resource) {
            $cursor = $ch->find({ "tag" => $tag })->fields({ $resource => 1 });
        } else {
            $cursor = $ch->find({ "tag" => $tag });
        }
        if ( $cursor->count() ) {
            $data = $cursor->next();
        }
    } else {
        debug "Getting all profiles...";
        $cursor = $ch->find();
        if ( $cursor->count() ) {
            $data = [ $cursor->all() ];
        }
    }

    if ( defined $data ) {
        if ( exists $data->{_id} && ref ( $data->{_id} ) ) {
            $data->{_id} = $data->{_id}->{value};
        }
        debug "Data:";
        debug Dumper ( $data );
    } else {
        debug "No data retrieved";
        $data = { status => 500, error => "No data retrieved" };
    }

    return $data;
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
    debug "/id...";
    my $section = params->{section};
    debug "Section: $section";
    my $id;
    $id = param('id') if ( defined param('id') );
    my $collection = config->{store}->{sections}->{ $section }
        or die "Error: no section $section configured";
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

    my $ch = $database->get_collection( $collection );
    my $data;
    $data = $ch->find_one({ $key => $value });

    return $data;
};

# default route handler...
any qr{.*} => sub {
    status 'not_found';
    return { status => '404', path => request->path };
};

true;

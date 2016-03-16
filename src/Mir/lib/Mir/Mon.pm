package Mir::Mon;
#============================================================= -*-perl-*-

=head1 NAME

Mir::Mon - a Mir class that provides some information regarding
the runtime environment. It helps monitoring the health of the
runtime environment configured for a campaign.

=head1 VERSION

0.0.1

=cut

our $VERSION='0.0.1';


=head1 SYNOPSIS

    use Mir::Mon;

    # get a Mir::Mon object, passing the
    # campaign tag and all parameters to
    # connect to the Mir::Config repository...
    my $o = Mir::Mon->new(
        campaign        => $campaign,
        config_driver   => $config_driver,
        config_params   => $config_params
    );

    # returns the number of items (fetchers)
    # waiting to get processed by the ACQ processor
    my $n1 = $o->number_items_acq_processor_queue();

    # returns an hashref with the numbers of documents
    # for each MongoDB collection configured for the
    # campaign
    # Hash keys are collection names
    my $n2 = $o->number_docs_store();

    # returns the number of keys in store cache
    # (NOTE: this is currently valid as cache is handled
    # in a Redis db)
    my $n3 = $o->number_keys_store_cache();

    # returns the number of items (doc profiles) 
    # waiting to get processed by the different mir-ir
    # processors.
    # It returns an hashref, the keys being the queue names
    my $n4 = $o->number_items_ir_queues();

    # returns the number of documents in the different
    # ElasticSearch indices configured
    my $n5 = $o->number_docs_indexes();

=head1 DESCRIPTION

This class can be used to collect data regarding the computation workflow
configured for a campaign.

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
use Queue::Q::ReliableFIFO::Redis;
use Mir::Config::Client;
use Mir::Store;
use Data::Dumper qw( Dumper );

has 'campaign'      => ( is => 'rw', isa => 'Str' );
has 'config_driver' => ( is => 'rw', isa => 'Str' );
has 'config_params' => ( is => 'rw', isa => 'HashRef' );
has 'config_obj'    => (
    is  => 'ro',
    isa => 'Object',
    lazy=> 1,
    builder => '_get_config_obj'
);
has 'acq_queue_server' => ( is => 'rw', isa => 'Str', default => "localhost" );
has 'acq_queue_port'   => ( is => 'rw', isa => 'Int', default => 6379 );
has 'acq_q' => ( 
    is => 'ro',
    isa => 'Queue::Q::ReliableFIFO::Redis',
    lazy=> 1,
    default => sub {
        my $self = shift;
        return Queue::Q::ReliableFIFO::Redis->new(
          server     => $self->acq_queue_server,
          port       => $self->acq_queue_port,
          queue_name => $self->campaign
      );
    }
);

#=============================================================

=head2 _get_config_obj

=head3 INPUT

The object

=head3 OUTPUT

The Mir::Config::Client object

=head3 DESCRIPTION

Returns the Mir::Config::Client driver object as defined
by the config parameters passed at construction time.

=cut

#=============================================================
sub _get_config_obj {
    my $self = shift;

    return undef unless ( $self->config_driver );
    my $o = Mir::Config::Client->create(
        driver  => $self->config_driver,
        params  => $self->config_params
    );
    $o->connect();
    return $o;
}

#=============================================================

=head2 number_items_acq_processor_queue 

=head3 INPUT

None

=head3 OUTPUT

=head3 DESCRIPTION

Returns the number of items (fetchers) present 
in the ACQ processor queue for the selected campaign.

=cut

#=============================================================
sub number_items_acq_processor_queue {
    my $self = shift;
    $DB::single=1;
    return $self->acq_q->queue_length();
}

#=============================================================

=head2 number_docs_store

=head3 INPUT

None

=head3 OUTPUT

An hashref

=head3 DESCRIPTION

Returns the number of documents in all the collections
configured.

=cut

#=============================================================
sub number_docs_store {
    my $self = shift;

    my @stores;
    my $stores_as_hash;

    unless ( $self->config_obj ) {
        $self->config_obj( $self->_get_config_obj() );
        $self->config_obj->connect();
    }
    my $fetchers = $self->config_obj->get_key({
            campaign => $self->campaign,
            tag      => 'ACQ'
        },
        { 'fetchers' => 1 }
    )->[0]->{ fetchers };
    foreach my $f ( @$fetchers ) {
        $DB::single=1;
        my ( $driver, $params ) = @{ $f->{params}->{storage_io_params}->{io} };
        my $store = Mir::Store->create(
            driver  => $driver,
            params  => $params,
        ) or die "Error getting a store object for fetcher:\n".Dumper $f."\n";
        $store->connect();
#        $stores_as_hash->{ join(':', values %{ $params }) } = $store->count();
        $stores_as_hash->{ join(':', map ({ $params->{$_} } sort keys %$params) ) } = $store->count();
        # I prefer returning an hash...
#        push @stores, {
#            %{$f->{params}->{storage_io_params}->{io}->[1]},
#            count => $store->count()
#        };
    }
    return $stores_as_hash;
}

#=============================================================

=head2 <func>

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

=cut

#=============================================================
sub number_keys_store_cache {
    my $self = shift;
}

#=============================================================

=head2 <func>

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

=cut

#=============================================================
sub number_items_ir_queues {
    my $self = shift;
}

#=============================================================

=head2 <func>

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

=cut

#=============================================================
sub number_docs_indexes {
    my $self = shift;
}

1;

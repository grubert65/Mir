package Mir::Acq::Fetcher::WU;
use Moose;
with 'Mir::R::Acq::Fetch';
use Mir::Doc::WU;

use WWW::Wunderground::API;
use JSON;
use Hash::AsObject;
use LWP::UserAgent;

# HISTORY
# 0.01 | 25.06.2015 | initial version
our $VERSION='0.01';

sub get_docs {
    my $self = shift;

    $self->check_params();

    my $json = JSON->new->allow_nonref;

    # remember that the api key is stored in $ENV{WUNDERGROUND_API} env var...
    my $wun = new WWW::Wunderground::API(
        location => $self->params->{city}.', '.$self->params->{country},
    );
    my $con = $wun->api_call('conditions');
    my $str = $wun->raw();
    my $h = $json->decode ( $str );
    my $doc = Mir::Doc::WU->new(
        current_observation => $h->{current_observation}
    );
    $doc->store;
    push @{ $self->docs }, $doc;
}

sub check_params {
    my $self = shift;

    foreach ( qw(
        city
        country
        )) {
        die "Param $_ not defined" unless defined $self->params->{$_};
    }
}


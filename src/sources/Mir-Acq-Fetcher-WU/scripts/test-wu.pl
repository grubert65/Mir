#!/usr/bin/env perl 
use strict;
use warnings;
use utf8;
use WWW::Wunderground::API;
use JSON;
use Hash::AsObject;
use LWP::UserAgent;
use Mir::Doc;

my $json = JSON->new->allow_nonref;
my $wun = new WWW::Wunderground::API('Genoa, IT');
my $con = $wun->api_call('conditions');
my $str = $wun->raw();
my $current_observation = {};
$current_observation = ( $json->decode ( $str ) )->{current_observation};
my $doc = bless $current_observation, 'Mir::Doc';
my $current_str = $json->canonical->pretty->encode( $current_observation );
print "$current_str\n";


=comment

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
 
my $resp = $ua->get('http://api.wunderground.com/api/f9a17cd41b53bb13/conditions/q/IT/Genoa.json');
if ($resp->is_success) {
    my $json_str = $resp->decoded_content;
    my $h = $json->decode ( $json_str );
    print $json->pretty->encode( $h->{current_observation} );
    print "\n";
} else {
    die $resp->status_line;
}

=cut




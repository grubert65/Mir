#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Redis;
use Data::Printer;
use JSON;
use Encode;

my $r = Redis->new()
    or die "Error: Redis server not running\n";

print "KEYS--------------\n";
print "$_\n" foreach( $r->keys( '*' ) );

print "Key ?: ";
my $key = <>;
chomp $key;

my $len = $r->llen( $key );
print "KEY $key has $len items\n";

print "Max items to print?:";
my $max = <>; chomp $max;

my $range = ( $len > $max ) ? $max : $len;

my $json_obj = JSON->new;

foreach ( my $i=0;$i<$range;$i++) {
    print "\n---------- Item $i: ---------------\n";
    my $json_str = $r->lindex( $key, $i );
    print "JSON string: \n$json_str\n";
    my $item = $json_obj->decode( $json_str );
    p $item;
    print "\n";
}




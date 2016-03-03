#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Redis;
use Data::Printer;
use JSON;

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

foreach ( my $i=0;$i<$range;$i++) {
    print "\n---------- Item $i: ---------------\n";
    $DB::single=1;
    my $item = decode_json( $r->lindex( $key, $i ) );
    p $item;
    print "\n";
}




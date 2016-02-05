#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: redis-queue.pl
#
#        USAGE: ./redis-queue.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/10/2016 04:46:51 PM
#     REVISION: ---
#===============================================================================
use strict;
use utf8;
no warnings 'experimental';
use Redis ();
use Getopt::Long;
use Data::Printer;

my $db  = 0;
my $key;
my $host = 'localhost';
my $port = 6379;
my $count = 10;

GetOptions(
    "db=i"      => \$db,
    "key=s"     => \$key,
    "host=s"    => \$host,
    "port=i"    => \$port,
    "count=i"   => \$count
) or die "Usage: $0 --db <a db> --key <a queue key> [--host <redis host>] [--port <redis port]\n";

my $r = Redis->new(server => "$host:$port");

my @queues = $r->keys('*_main');
print scalar @queues." potential queues found\n";
p @queues;

die "Use a --key <a queue key> to browse a queue content\n" unless $key;
die "Queue $key does not exists!\n"
    unless ( $key ~~ @queues );

my $len = $r->llen( $key );
print "Queue $key has $len items\n";

my $max = ( $len > $count ) ? $count : $len;
print "First $len items of queue $key\n";
p $r->lrange( $key, 0, $max-1);

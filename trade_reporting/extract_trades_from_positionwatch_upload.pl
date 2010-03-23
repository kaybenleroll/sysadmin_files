#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;

my $user_list = "JS004JS,JACOBSEC";

GetOptions("user_list=s" => \$user_list);

$user_list =~ s/\,/\|/g;

while(my $line = <STDIN>) {
    chomp($line);

    my @data = split("\t", $line);

    my $symbol      = $data[2];
    my $venue       = $data[3];
    my $timestamp   = $data[5];
    my $exchorderid = $data[6];
    my $price       = $data[10];
    my $qty         = $data[11];
    my $side        = $data[12];

    my $userid    = $data[20];
    my $liquidity = $data[31];

    next unless $userid =~ /(${user_list})/;

    $side  = ($side  eq 'B')  ? 'BUY'  : 'SELL';
    $venue = ($venue eq 'US') ? $venue : 'CA';

    print "PW,$venue,$symbol,$side,$qty,$price,,,$timestamp,$exchorderid,$liquidity\n";
}

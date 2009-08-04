#!/usr/bin/perl -w

use strict;
use warnings;

my %positions;

while(my $line = <>) {
    if ($line =~ /.*OrderUpdate\((.*)\)/){


    my @data = split(",", $1);
    my %hash;

    my $orderid   = $data[0];
    my $symbol    = $data[1];
    my $side      = $data[3];
    my $executed  = $data[14];
    my $remaining = $data[15];
    my $price     = $data[18];
    my $status    = $data[19];


    next unless $orderid =~ /^"[^_]/;
    next unless $status  =~ /Filled:/;

    $symbol =~ s/"//g;
    $side   =~ s/"//g;

    my $venue;

    if($line =~ /TSX_TRADING/) {
	$venue = "CA";
    } elsif($line =~ /TORC_TRADING/) {
	$venue = "US";
    } elsif($line =~ /CURRENEX_TRADING/) {
	$venue = "CNX";
    } else {
	print "Error parsing entry $line";
    }

    my $printprice;

    if($venue eq "CNX") {
	$printprice = sprintf("%8.6f", $price);
    } else {
	$printprice = sprintf("%4.2f", $price);
    }


    $hash{$orderid} = "$venue,$symbol,$side,$executed,$remaining,$printprice";
    print "$hash{$orderid}\n";

    
    $positions{"$venue"}{"$symbol"}{"$side"}{"count"} += 1;
    $positions{"$venue"}{"$symbol"}{"$side"}{"quantity"} += $executed;
    $positions{"$venue"}{"$symbol"}{"$side"}{"money"} += $executed * $price;
    }
}

exit(0);

print "\n\nSummary:\n\n";


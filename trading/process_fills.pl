#!/usr/bin/perl -w

use strict;
use warnings;

use Time::ParseDate;

my %positions;
my %hash;
my $k;
my $timestamp;
my $epoch;

while(my $line = <>) {
    
    $line =~ /^(.*?) CRIT/;
    $timestamp = $1;
    $epoch = parsedate($timestamp);

    if ($line =~ /.*OrderUpdate\((.*)\)/){

        my @data = split(",", $1);

        my $orderid   = $data[0];
        my $symbol    = $data[1];
        my $side      = $data[3];
        my $executed  = $data[14];
        my $remaining = $data[15];
        my $price     = $data[18];
        my $status    = $data[19];

        next unless $orderid =~ /^"[^_]/;
        next unless $status  =~ /Filled:/;
        next unless ($orderid && $orderid ne "\"\""); 

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
        $printprice = sprintf("%8.6f", $price);
    
        $hash{$orderid} = "$venue,$symbol,$side,$executed,$remaining,$printprice,$orderid,$timestamp,$epoch";

        $positions{"$venue"}{"$symbol"}{"$side"}{"count"} += 1;
        $positions{"$venue"}{"$symbol"}{"$side"}{"quantity"} += $executed;
        $positions{"$venue"}{"$symbol"}{"$side"}{"money"} += $executed * $price;
    }
}

foreach $k (sort keys %hash) {
    print "$hash{$k}\n";
}

exit(0);

print "\n\nSummary:\n\n";


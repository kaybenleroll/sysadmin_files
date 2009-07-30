#!/usr/bin/perl -w

use strict;
use warnings;

my %positions;

while(my $line = <>) {
    
    if ($line =~ /.*4PABCRF(.*).*/){

    my @data = split(",", $1);

    my $orderid   = $data[0];
    my $symbol    = $data[8];
    my $side      = $data[6];
    my $executed  = $data[4];
    my $price     = $data[5];


    $symbol =~ s/"//g;
    
    if ($side eq "B"){
        $side = "BUY";
    }
    elsif ($side eq "S"){
        $side = "SELL";
    }

    my $venue;

    my $printprice;

    $printprice = sprintf("%4.2f", $price);
    

    print "US,$symbol,$side,$executed,0,$printprice\n";
    }
}

exit(0);

print "\n\nSummary:\n\n";


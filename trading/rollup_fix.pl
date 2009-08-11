#!/usr/bin/perl -w

use strict;
use warnings;

my %positions;
my %fieldhash;
my %hash;
my $k;

while(my $line = <>) {
    
    if ($line =~ /.*35=8(.*).*/){

        my @data = split("\x01", $1);
    
        foreach my $field (@data){
            $field =~ /(\d+)=(.*)/;
            $fieldhash{$1} = $2;
        }
        my $orderid   = undef;
        my $symbol    = undef;
        my $side      = undef;
        my $executed  = undef;
        my $price     = undef;
        my $ordstatus = undef;
        my $venue     = undef;
        $orderid   = $fieldhash{11};
        $symbol    = $fieldhash{55};
        $side      = $fieldhash{54};
        $ordstatus = $fieldhash{39};
        $venue     = $fieldhash{56};



        if ($venue eq "JACOB01"){
            $venue = "US";
            $price     = $fieldhash{31};
            $executed  = $fieldhash{32};
        }
        elsif ($venue eq "PGR"){
            $venue = "CA";
            $price     = $fieldhash{44};
            $executed  = $fieldhash{38};
        }

        $symbol =~ s/"//g;
    
        if ($side eq "1"){
            $side = "BUY";
        }
        elsif ($side eq "2"){
            $side = "SELL";
        }

        my $printprice;

        $printprice = sprintf("%8.6f", $price);
 
        if ($ordstatus eq "2"){
            $hash{$orderid} = "$venue,$symbol,$side,$executed,0,$printprice,$orderid";
        }
    }
}

foreach $k (sort keys %hash) {
    print "$hash{$k}\n";
}

exit(0);

print "\n\nSummary:\n\n";


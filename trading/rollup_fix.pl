#!/usr/bin/perl -w

use strict;
use warnings;

my %positions;
my %fieldhash;

while(my $line = <>) {
    
    if ($line =~ /.*35=8(.*).*/){

        my @data = split("\x01", $1);
    
        foreach my $field (@data){
            $field =~ /(\d+)=(.*)/;
            $fieldhash{$1} = $2;
        }

        my $orderid   = $fieldhash{11};
        my $symbol    = $fieldhash{55};
        my $side      = $fieldhash{54};
        my $executed  = $fieldhash{38};
        my $price     = $fieldhash{44};
        my $ordstatus = $fieldhash{39};

        $symbol =~ s/"//g;
    
        if ($side eq "1"){
            $side = "BUY";
        }
        elsif ($side eq "2"){
            $side = "SELL";
        }

        my $venue;

        my $printprice;

        $printprice = sprintf("%8.6f", $price);
        if ($ordstatus = 2){
            print "CA,$symbol,$side,$executed,0,$printprice,$orderid\n";
        }
    }
}

exit(0);

print "\n\nSummary:\n\n";


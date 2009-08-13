#!/usr/bin/perl -w

use strict;
use warnings;


while(my $line = <>) {
    
    #Filters out all none data lines and splits data lines along commas
    if ($line =~ /.*4PABCRF(.*).*/){

        my @data = split(",", $1);
       
        #Assigns data to their respective variables
        my $orderid   = $data[0];
        my $symbol    = $data[8];
        my $side      = $data[6];
        my $executed  = $data[4];
        my $price     = $data[5];

        #Removes quotation marks from around symbol
        $symbol =~ s/"//g;
    
        #Switches side from single letter to word format
        if ($side eq "B"){
            $side = "BUY";
        }
        elsif ($side eq "S"){
            $side = "SELL";
        }

        #Rounds price to 6 decimal places
        my $printprice = sprintf("%8.6f", $price);
    
        #Prints data in trades file / processfills format
        print "US,$symbol,$side,$executed,0,$printprice\n";
    }
}

exit(0);

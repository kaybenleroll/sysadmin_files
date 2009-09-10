#!/usr/bin/perl -w

use strict;
use warnings;

#Declaration of variables
my %fieldhash;
my %hash;
my $k;

while(my $line = <>) {
    
    #Filters out trade lines by matching for 35=8
    if ($line =~ /.*35=8(.*).*/){

        #Splits data in fields along the divider
        my @data = split("\x01", $1);
    
        #Takes every field in data array and splits data along equals signs, uses first value as hash key and second as hash value
        foreach my $field (@data){
            $field =~ /(\d+)=(.*)/;
            $fieldhash{$1} = $2;
        }

        #Assigns data to their given variables
        my $orderid   = $fieldhash{11};
        my $symbol    = $fieldhash{55};
        my $side      = $fieldhash{54};
        my $executed  = undef;
        my $price     = undef;
        my $ordstatus = $fieldhash{39};
        my $venue     = $fieldhash{56};

        #Checks to see if the venue is US or CA and assigns the correct venue to venue variable
        #Also assigns price and executed to their given variable as they key differs depending on the venue 
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

        #Removes any quotation marks from symbol
        $symbol =~ s/"//g;

        #Changes side from number to word format    
        if ($side eq "1"){
            $side = "BUY";
        }
        elsif ($side eq "2"){
            $side = "SELL";
        }

        #Rounds price to 6 decimal places
        my $printprice = sprintf("%8.6f", $price);
 
        #If the order status is 1 (partial fill) or 2 (full fill) add the data to a hash with the key being the orderid.
        #Therefore if same order appears twice it will overwrite the previous order and only be printed once
        if ($ordstatus eq "1"){
            $hash{$orderid} = "$venue,$symbol,$side,$executed,0,$printprice,$orderid";
        } 
        if ($ordstatus eq "2"){
            $hash{$orderid} = "$venue,$symbol,$side,$executed,0,$printprice,$orderid";
        }
    }
}

#Prints out the entire hash with all the orders
foreach $k (sort keys %hash) {
    print "$hash{$k}\n";
}

exit(0);


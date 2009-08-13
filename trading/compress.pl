#!/usr/bin/perl -w

use strict;
use warnings;

#Declare variables
my %positions;
my %partialhash;
my %fullhash;
my $k;

#Takes every line given through standard input and pulls the venue symbol side quantity and price from it
while(my $line = <>) {
    
    my ($venue, $symbol, $side, $qty, $price) = split(",", $line);

    #If the quantity was not 100 ie the trade was a partial fill add the trade data to partial fill hash.
    if ($qty != 100) 

        $partialhash{$venue}{$symbol}{$side}{$price} += $qty;

        # If two partial fills now equal 100 shares ie fully filled print out data.
        if ($partialhash{$venue}{$symbol}{$side}{$price} == 100){
            print "$venue,$symbol,$side,$partialhash{$venue}{$symbol}{$side}{$price},0,$price\n";
            $partialhash{$venue}{$symbol}{$side}{$price} = 0;
        }
    }else{
        #If not a partial fill print out data 
        print "$venue,$symbol,$side,$qty,0,$price\n";
    }

        
}

#Goes through every value in partial fill hash and if the quantity is not zero prints out the data
#Prints out and partially filled trades
foreach my $venue (sort keys %partialhash) {
    foreach my $symbol (sort keys %{ $partialhash{"$venue"} }) {
	foreach my $side (sort keys %{ $partialhash{"$venue"}{"$symbol"} }) {
                foreach my $price (sort keys %{ $partialhash{"$venue"}{"$symbol"}{"$side"} }) {                
                    if ($partialhash{$venue}{$symbol}{$side}{$price} != 0){
                        print"$venue,$symbol,$side,$partialhash{$venue}{$symbol}{$side}{$price},0,$price\n";
                    }
                }
            
        }
    }
}


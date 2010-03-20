#!/usr/bin/perl -w

use strict;
use warnings;

### Declaration of variables
my %fieldhash;
my %hash;
my $k;

while(my $line = <>) {
    ### Filters out trade lines by matching for 35=8
    if ($line =~ /35=8/) {
        ### Splits data in fields along the divider
        my @data = split("\x01", $line);

        ### Takes every field in data array and splits data along equals signs, uses first value as hash key and second as hash value
        foreach my $field (@data) {
            $field =~ /(\d+)=(.*)/;
            $fieldhash{"$1"} = $2;
        }

        next unless ($fieldhash{"35"} eq "8");
        next unless (($fieldhash{"150"} eq "1") or ($fieldhash{"150"} eq "2"));

        ### Assigns data to their given variables
        my $clorderid = $fieldhash{'11'};
        my $orderid   = $fieldhash{'37'};
        my $symbol    = $fieldhash{"55"};
        my $side      = $fieldhash{"54"};
        my $price     = $fieldhash{"31"};
        my $executed  = $fieldhash{"32"};
        my $ordstatus = $fieldhash{"39"};
        my $compid    = $fieldhash{"56"};
        my $execid    = $fieldhash{"17"};
        my $timestamp = $fieldhash{"60"};

        ### Checks to see if the venue is US or CA and assigns the correct venue to venue variable
        ### Also assigns price and executed to their given variable as they key differs depending on the venue
        my $venue;
        my $liquidity = '';

        if(($compid eq "JACOB") or ($compid eq "01102031") or ($compid eq "PGR")) {
            $venue = "CA";
            $liquidity = $fieldhash{'6780'};

        } elsif($compid eq "JACOB01") {
            $venue = "US";
            $liquidity = $fieldhash{'9730'};
        } elsif($compid eq "pfsc1802") {
            $venue = "CNX";
        } else {
            $venue = "ERROR-" . $compid;
        }

        ### Removes any quotation marks from symbol
        $symbol =~ s/"//g;

        ### Changes side from number to word format
        if($side eq "1") {
            $side = "BUY";
        } elsif(($side eq "2") or ($side eq "5") or ($side eq "6")) {
            $side = "SELL";
        } else {
            $side = "ERROR";
        }

        ### Rounds price to 6 decimal places
        my $printprice = sprintf("%8.6f", $price);

        (my $printline = $line) =~ s/\x01/ /g;

        print "FIX,$venue,$symbol,$side,$executed,0,$printprice,$clorderid,$execid,$timestamp,$orderid,$liquidity\n";
    }
}


exit(0);

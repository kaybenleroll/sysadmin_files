#!/usr/bin/perl -w

use strict;
use warnings;



### While statement that takes every line passed into the program through standard input and adds their volumes and premiums to their respective venue's variables
while(my $line = <STDIN>) {
    my ($venue, $symbol, $side, $qty, $price) = split(",", $line);

    if($venue eq "CNX") {
        $usd_fx                  += ($qty          * ($side eq "BUY" ?  1 : -1));
        $cad_fx                  += ($qty * $price * ($side eq "BUY" ? -1 :  1));
    } elsif($venue eq "CA") {
        $ca_positions{"$symbol"} += ($qty          * ($side eq "BUY" ?  1 : -1));
        $cad_cashflow            += ($qty * $price * ($side eq "BUY" ? -1 :  1));
        $ca_volume               += ($qty         );
        $ca_cashvolume           += ($qty * $price);
    } elsif($venue eq "US") {
        $us_positions{"$symbol"} += ($qty          * ($side eq "BUY" ?  1 : -1));
        $usd_cashflow            += ($qty * $price * ($side eq "BUY" ? -1 :  1));
        $us_volume               += ($qty         );
        $us_cashvolume           += ($qty * $price);
    } else {
        print "Error with line $line";
    }
}

### Open's the csv file InterlistedStocks and greats a hash with the key the canadian symbol and the value the us symbol
print "Not flat:\n";

open(FILE, "InterlistedStocks.csv") || die ("Could not open file InterlistedStocks.csv");

while(my $line = <FILE> ) {
    my ($casymbol, $ussymbol) = split(",", $line);
    $casymbol =~ s/"//g;
    $ussymbol =~ s/"//g;
    $casymbol =~ s/\n//g;
    $ussymbol =~ s/\n//g;
    $interlistedhash{$casymbol} = $ussymbol;
}

close(FILE);

### For every symbol, it adds it's canadian and us equivalents together to calculate their overall position
### If position is not 0, program outputs the position
foreach my $symbol (sort keys %ca_positions) {
    my $us_symbol;

    if($interlistedhash{"$symbol"}) {
        $us_symbol = $interlistedhash{"$symbol"};

        if (!$us_positions{"$us_symbol"}){
            $us_positions{"$us_symbol"} = 0;
        }

        $offset = $ca_positions{"$symbol"} + $us_positions{"$us_symbol"};

        if ($offset != 0) {
            print "$symbol\\$us_symbol : $offset\n";
            $count = 1;
        }
    }
}

### If all stocks are flat prints out None
if ($count == 0) {
    print "None";
}

### Calculates unhedged pnl
$unhedged_pnl = $usd_cashflow * $exchange_rate + $cad_cashflow;

### Prints out US and Canadian Cash Volume, Volume, Cashflow, FX and Total as well as the Unhedged PNL
print "\n\n";
print "CAD Cashflow: " . sprintf("% 10.2f", $cad_cashflow) . "\n";
print "CAD FX:       " . sprintf("% 10.2f", $cad_fx) . "\n";
print "CAD Total:    " . sprintf("% 10.2f", $cad_fx + $cad_cashflow) . "\n";
print "\n";
print "USD Cashflow: " . sprintf("% 10.2f", $usd_cashflow) . "\n";
print "USD FX:       " . sprintf("% 10.2f", $usd_fx) . "\n";
print "USD Total:    " . sprintf("% 10.2f", $usd_fx + $usd_cashflow) . "\n";
print "\n";
print "CA Cash Volume: " . sprintf("% 10.2f", $ca_cashvolume) . "\n";
print "CA Volume       " . sprintf("% 10.2f", $ca_volume) . "\n";
print "US Cash Volume: " . sprintf("% 10.2f", $us_cashvolume) . "\n";
print "US Volume       " . sprintf("% 10.2f", $us_volume) . "\n";
print "\n";
print "Unhedged PNL: " . sprintf("%10.2f", $unhedged_pnl) . "\n";


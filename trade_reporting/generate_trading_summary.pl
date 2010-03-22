#!/usr/bin/perl -w

use strict;
use warnings;


my %positions;
my %symbol_pnl;

while(my $line = <STDIN>) {
    my ($entrysrc, $venue, $symbol, $side, $qty, $price, $clorderid, $execid, $timestamp, $exchorderid, $liquidity) = split(",", $line);

    $positions{"$venue"}{"$symbol"}{"$side"}{"count"}    += 1;
    $positions{"$venue"}{"$symbol"}{"$side"}{"quantity"} += $qty;
    $positions{"$venue"}{"$symbol"}{"$side"}{"money"}    += $qty * $price;

    $symbol_pnl{"$venue"}{"$symbol"}{"position"} += ($side eq "SELL" ? -1 :  1) * $qty;
    $symbol_pnl{"$venue"}{"$symbol"}{"money"}    += ($side eq "SELL" ?  1 : -1) * ($qty * $price);
}



foreach my $venue (sort keys %positions) {
    my $total_currency = 0;

    next if $venue eq "CNX";

    foreach my $symbol (sort keys %{ $positions{"$venue"} }) {
        foreach my $side (sort keys %{ $positions{"$venue"}{"$symbol"} }) {
            my $fills     = $positions{"$venue"}{"$symbol"}{"$side"}{"count"};
            my $shares    = $positions{"$venue"}{"$symbol"}{"$side"}{"quantity"};
            my $avg_price = sprintf("%0.6f", $positions{"$venue"}{"$symbol"}{"$side"}{"money"} / $shares);

            print "$venue,$symbol,$side,$shares,$avg_price\n";

            next if $venue =~ /CNX/;

            $total_currency += $positions{"$venue"}{"$symbol"}{"$side"}{"money"} * ($side eq "BUY" ? -1 : 1);
        }
    }

    print sprintf("\n%s, %9.2f\n\n", $venue, $total_currency) unless $venue =~ /CNX/;
}


print "Price Summary:\n";

foreach my $venue (sort keys %positions) {
    foreach my $symbol (sort keys %{ $positions{"$venue"} }) {
        my $avg_price = 0;

        if($symbol_pnl{"$venue"}{"$symbol"}{"position"} != 0) {
            $avg_price = abs($symbol_pnl{"$venue"}{"$symbol"}{"money"} / $symbol_pnl{"$venue"}{"$symbol"}{"position"});
        }

        print sprintf("%3s,%10s,% 9d,% 12.2f,% 11.6f\n",
                      $venue,
                      $symbol,
                      $symbol_pnl{"$venue"}{"$symbol"}{"position"},
                      $symbol_pnl{"$venue"}{"$symbol"}{"money"},
                      $avg_price);
    }

    print "\n";
}


#!/usr/bin/perl -w

use strict;
use warnings;


my %positions;

while(my $line = <>) {
    my ($venue, $symbol, $side, $qty, $remain, $price) = split(",", $line);

    $positions{"$venue"}{"$symbol"}{"$side"}{"count"}    += 1;
    $positions{"$venue"}{"$symbol"}{"$side"}{"quantity"} += $qty;
    $positions{"$venue"}{"$symbol"}{"$side"}{"money"}    += $qty * $price;
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

    print "\n$venue,${total_currency}\n\n" unless $venue =~ /CNX/;
}


#!/usr/bin/perl -w

my %tradelist;


while(<>) {
    chomp();

    my ($venue, $symbol, $side, $qty, $remain, $price) = split(",");

    if($side eq "SELL") { $qty *= -1 };

    if($tradelist{"$venue-$symbol"}{"$price"}) {
        $tradelist{"$venue-$symbol"}{"$price"} += $qty;
    } else {
        $tradelist{"$venue-$symbol"}{"$price"} = $qty;
    }
}


foreach my $symbol (sort keys %tradelist) {
    foreach my $price (sort keys %{ $tradelist{"$symbol"} }) {
	if($tradelist{"$symbol"}{"$price"}) {
	    print "$symbol,$price," . $tradelist{"$symbol"}{"$price"} . "\n";
	}
    }
}


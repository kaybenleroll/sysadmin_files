#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;

my $symbol_list = "ABX.TO,ABX.,RY.TO,RY.,G.TO,GG.,SU.TO,SU.,XIU.TO,XEG.TO,XIT.TO,SPY.,QQQQ.,CNQ.TO,CNQ.,USD/CAD";


my @symbols = split(",", $symbol_list);

my $regexp = "(," . join(",|,", @symbols) . ",)";

while(my $line = <>) {
    print $line if $line =~ /$regexp/;
}

exit(0);

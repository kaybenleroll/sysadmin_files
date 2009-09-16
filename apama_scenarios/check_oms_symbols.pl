#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

my $symbol_file = "InterlistedStocks.csv";


open(FILE, $symbol_file) or die("Unable to open $symbol_file");

my %tied_symbols;


while(<FILE>) {
    my ($ca_symbol, $us_venue, $us_symbol) = split(",");
    
    $tied_symbols{$ca_symbol} = $us_symbol;
}


while(<>) {
    /(.*?)(?:.TO)? -> (.*?).?$/;

    my $first  = $1;
    my $second = $2;

    
    if($tied_symbols{"$first"} ne $second) {
        print "Found $second   Expected " . $tied_symbols{"$first"} . "\n";
    }
}

#!/usr/bin/perl -w

use strict;
use warnings;

my $cad_cashflow = 0;
my $usd_cashflow = 0;
my $ca_volume = 0;
my $us_volume = 0;
my $ca_cashvolume = 0;
my $us_cashvolume = 0;

my $cad_fx = 0;
my $usd_fx = 0;

my %ca_positions;
my %us_positions;



while(my $line = <>) {
    my ($venue, $symbol, $side, $qty, $remain, $price) = split(",", $line);

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


foreach my $symbol (sort keys %ca_positions) {
    print $symbol . "," . $ca_positions{"$symbol"} . "\n"; 
}

print "\n";

foreach my $symbol (sort keys %us_positions) {
    print $symbol . "," . $us_positions{"$symbol"} . "\n"; 
}

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


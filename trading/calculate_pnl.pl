#!/usr/bin/perl -w

use strict;
use warnings;

#Declaration and Initialization of Variables
my $cad_cashflow = 0;
my $usd_cashflow = 0;
my $ca_volume = 0;
my $us_volume = 0;
my $ca_cashvolume = 0;
my $us_cashvolume = 0;
my $unhedged_pnl = 0;
my $exchange_rate = 0;
my $count = 0;
my $offset = 0;

my $cad_fx = 0;
my $usd_fx = 0;

my %interlistedhash;
my %ca_positions;
my %us_positions;


#While statement that takes every line passed into the program through standard input and adds their volumes and premiums to their respective venue's variables
while(my $line = <>) {
    my ($venue, $symbol, $side, $qty, $remain, $price) = split(",", $line);

    if($venue eq "CNX") {
	$usd_fx                  += ($qty          * ($side eq "BUY" ?  1 : -1));
	$cad_fx                  += ($qty * $price * ($side eq "BUY" ? -1 :  1));
        $exchange_rate            = ($price        +(($side eq "BUY" ? -1 :  1)*0.00025));
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

# Prints out every canadian symbol and their respective positions
foreach my $symbol (sort keys %ca_positions) {
    print $symbol . "," . $ca_positions{"$symbol"} . "\n"; 
}

print "\n";

# Prints out every us symbol and their respective positions
foreach my $symbol (sort keys %us_positions) {
    print $symbol . "," . $us_positions{"$symbol"} . "\n"; 
}

print "\n";

# Open's the csv file InterlistedStocks and greats a hash with the key the canadian symbol and the value the us symbol
print "Not flat:\n";

open(FILE, "InterlistedStocks.csv") || die ("Could not open file!");

while(my $line = <FILE> ) {
    my ($casymbol, $ussymbol) = split(",", $line);
    $casymbol =~ s/"//g;
    $ussymbol =~ s/"//g;
    $casymbol =~ s/\n//g;
    $ussymbol =~ s/\n//g;
    $interlistedhash{$casymbol} = $ussymbol;     
}

close(FILE);

#For every symbol, it adds it's canadian and us equivalents together to calculate their overall position
#If position is not 0, program outputs the position
foreach my $symbol (sort keys %ca_positions) {
    if (!$us_positions{$interlistedhash{$symbol}}){
        $us_positions{$interlistedhash{$symbol}} = 0;
    }
    $offset = $ca_positions{$symbol} + $us_positions{$interlistedhash{$symbol}};
    if ($offset != 0) {
        print "$symbol\\$interlistedhash{$symbol} : $offset\n";
        $count = 1;
    }
}

#If all stocks are flat prints out None
if ($count == 0) {
    print "None";
}

#Calculates unhedged pnl
$unhedged_pnl = $usd_cashflow * $exchange_rate + $cad_cashflow;

#Prints out US and Canadian Cash Volume, Volume, Cashflow, FX and Total as well as the Unhedged PNL
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



#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;

my $exchange_rate = 1.05;

my $ca_fee    = -0.0035;
my $ca_rebate = +0.0031;

my $us_fee    = -0.0040;
my $us_rebate = +0.0014;

my $ticket_charge = -4.00;


GetOptions('exchange_rate=s'   => \$exchange_rate);


my %tickets;
my $ticket_count = 0;

my (%ca_positions,  %us_positions);

my $ca_volume = 0;
my $us_volume = 0;

my $ca_cashvolume = 0;
my $us_cashvolume = 0;

my $cad_cashflow = 0;
my $usd_cashflow = 0;

my $cad_fx = 0;
my $usd_fx = 0;

my $ca_active  = 0;
my $ca_passive = 0;
my $us_active  = 0;
my $us_passive = 0;

#        print "FIX,$venue,$symbol,$side,$executed,$printprice,$clorderid,$execid,$timestamp,$orderid,$liquidity\n";


### While statement that takes every line passed into the program through standard input and adds their volumes and premiums to their respective venue's variables
while(my $line = <STDIN>) {
    my ($entrysrc, $venue, $symbol, $side, $qty, $price, $clorderid, $execid, $timestamp, $exchorderid, $liquidity);

    if($line =~ /^FIX/) {
        ($entrysrc, $venue, $symbol, $side, $qty, $price, $clorderid, $execid, $timestamp, $exchorderid, $liquidity) = split(",", $line);
    } elsif($line =~ /^PW/) {
        ($entrysrc, $venue, $symbol, $side, $qty, $price, $clorderid, $execid, $timestamp, $exchorderid, $liquidity) = split(",", $line);
    } else {
        print "Invalid line - $line";
        next;
    }

    if($venue eq "CNX") {
        $usd_fx                  += ($qty          * ($side eq "BUY" ?  1 : -1));
        $cad_fx                  += ($qty * $price * ($side eq "BUY" ? -1 :  1));

    } elsif($venue eq "CA") {
        $ca_positions{"$symbol"} += ($qty          * ($side eq "BUY" ?  1 : -1));
        $cad_cashflow            += ($qty * $price * ($side eq "BUY" ? -1 :  1));
        $ca_volume               += ($qty         );
        $ca_cashvolume           += ($qty * $price);

        if(substr($liquidity, 1, 1) eq 'P') {
            $ca_passive += $qty;
        } else {
            $ca_active  += $qty;
        }

        if(!exists $tickets{"$side-$symbol"}) {
            $tickets{"$side-$symbol"} = 1;
            $ticket_count++;
        }

    } elsif($venue eq "US") {
        $us_positions{"$symbol"} += ($qty          * ($side eq "BUY" ?  1 : -1));
        $usd_cashflow            += ($qty * $price * ($side eq "BUY" ? -1 :  1));
        $us_volume               += ($qty         );
        $us_cashvolume           += ($qty * $price);

        if($liquidity eq 'A') {
            $us_passive += $qty;
        } else {
            $us_active  += $qty;
        }

        if(!exists $tickets{"US-$symbol"}) {
            $tickets{"US-$symbol"} = 1;
            $ticket_count++;
        }

    } else {
        print "Error with line $line";
    }
}

### Open's the csv file InterlistedStocks and greats a hash with the key the canadian symbol and the value the us symbol
my %interlistedhash;

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
my $count = 0;
my $offset;

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
my $ca_tnxcosts = ($ca_active * $ca_fee) + ($ca_passive * $ca_rebate);
my $us_tnxcosts = ($us_active * $us_fee) + ($us_passive * $us_rebate);


my $unhedged_pnl = ($usd_cashflow + $usd_fx) * $exchange_rate + ($cad_cashflow + $cad_fx);

### Prints out US and Canadian Cash Volume, Volume, Cashflow, FX and Total as well as the Unhedged PNL
print "\n\n";
print "CAD Cashflow:      " . sprintf("% 10.2f", $cad_cashflow) . "\n";
print "CAD FX:            " . sprintf("% 10.2f", $cad_fx) . "\n";
print "CAD Total:         " . sprintf("% 10.2f", $cad_fx + $cad_cashflow) . "\n";
print "\n";
print "USD Cashflow:      " . sprintf("% 10.2f", $usd_cashflow) . "\n";
print "USD FX:            " . sprintf("% 10.2f", $usd_fx) . "\n";
print "USD Total:         " . sprintf("% 10.2f", $usd_fx + $usd_cashflow) . "\n";
print "\n";
print "CA Active Volume:  " . sprintf("% 10d",   $ca_active) . "\n";
print "CA Passive Volume: " . sprintf("% 10d",   $ca_passive) . "\n";
print "CA Volume:         " . sprintf("% 10d",   $ca_volume) . "\n";
print "CA Cash Volume:    " . sprintf("% 10.2f", $ca_cashvolume) . "\n";
print "US Active Volume:  " . sprintf("% 10d",   $us_active) . "\n";
print "US Passive Volume: " . sprintf("% 10d",   $us_passive) . "\n";
print "US Volume:         " . sprintf("% 10d",   $us_volume) . "\n";
print "US Cash Volume:    " . sprintf("% 10.2f", $us_cashvolume) . "\n";
print "\n";
print "Unhedged PNL:      " . sprintf("%10.2f", $unhedged_pnl) . "\n";
print "\n";
print "CAD Fees:          " . sprintf("%10.2f", $ca_tnxcosts) . "\n";
print "USD Fees:          " . sprintf("%10.2f", $us_tnxcosts) . "\n";
print "Net Fees:          " . sprintf("%10.2f", $ca_tnxcosts + ($us_tnxcosts * $exchange_rate)) . "\n";
print "\n";
print "Tickets: (" . $ticket_count . ") " . sprintf("%10.2f", $ticket_count * $ticket_charge) . "\n";

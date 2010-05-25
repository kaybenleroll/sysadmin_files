#!/usr/bin/perl -w

use strict;
use warnings;

my %venues;
my %vlmtraded;
my %dollarvlmtraded;
my %vlmpassive;
my %vlmactive;
my %netpos;
my %netposvalue;
my %netcash;
my %pnl;
my %lastprice;


while(my $line = <>) {

    ### Splits data in fields along the divider
    my @data = split(",", $line);

    ### Assigns data to their given variables
    my $trade_source = $data[0];
    my $venue        = $data[1];
    my $symbol       = $data[2];
    my $side         = $data[3];
    my $executed     = $data[4];
    my $printprice   = $data[5];
    my $clorderid    = $data[6];
    my $execid       = $data[7];
    my $timestamp    = $data[8];
    my $orderid      = $data[9];
    my $liquidity    = $data[10];

    if (!$vlmtraded{$symbol}{$venue}) {
        $venues{$symbol}{$venue} = 0;
        $vlmtraded{$symbol}{$venue} = 0;
        $dollarvlmtraded{$symbol}{$venue} = 0;
        $vlmpassive{$symbol}{$venue} = 0;
        $vlmactive{$symbol}{$venue} = 0;
        $netpos{$symbol}{$venue} = 0;
        $netposvalue{$symbol}{$venue} = 0;
        $netcash{$symbol}{$venue} = 0;
        $pnl{$symbol}{$venue} = 0;
    }

    $lastprice{$symbol}{$venue} = $printprice;
    $vlmtraded{$symbol}{$venue} += $executed;
    $dollarvlmtraded{$symbol}{$venue} += ($executed * $printprice);

    if ($liquidity eq 'TPPNN'||$liquidity eq 'XPPNN' ) {
        $vlmpassive{$symbol}{$venue} += $executed;
    } else {
        $vlmactive{$symbol}{$venue} += $executed;
    }

    if ($side eq 'BUY') {
        $netpos{$symbol}{$venue} += $executed;     
        $netcash{$symbol}{$venue} -= ($executed * $printprice);
    } elsif ($side eq 'SELL') {
        $netpos{$symbol}{$venue} -= $executed;
        $netcash{$symbol}{$venue} += ($executed * $printprice);
    }
  
}

foreach my $symbol (sort keys %lastprice) {
    foreach my $venue (sort keys %{$lastprice{$symbol}}) {
        $netposvalue{$symbol}{$venue} = $netpos{$symbol}{$venue} * $lastprice{$symbol}{$venue};
        $pnl{$symbol}{$venue} = $netposvalue{$symbol}{$venue} + $netcash{$symbol}{$venue};
        print "$venue,$symbol,$vlmtraded{$symbol}{$venue},$dollarvlmtraded{$symbol}{$venue},$vlmpassive{$symbol}{$venue},$vlmactive{$symbol}{$venue},$netpos{$symbol}{$venue},$netposvalue{$symbol}{$venue},$netcash{$symbol}{$venue},$pnl{$symbol}{$venue}\n";
    }
}
exit(0);

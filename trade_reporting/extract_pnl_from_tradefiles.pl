#!/usr/bin/perl -w

use strict;
use warnings;

### Declaring all global variables
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
    my ($trade_source,$venue,$symbol,$side,$executed,$printprice,$clorderid,$execid,$timestamp,$orderid,$liquidity) = split(",", $line);

    ### Initializing variables to 0 if symbol is not yet been used
    if (!$vlmtraded{"$venue"}{"$symbol"}) {
        $vlmtraded{"$venue"}{"$symbol"}       = 0;
        $dollarvlmtraded{"$venue"}{"$symbol"} = 0;
        $vlmpassive{"$venue"}{"$symbol"}      = 0;
        $vlmactive{"$venue"}{"$symbol"}       = 0;
        $netpos{"$venue"}{"$symbol"}          = 0;
        $netposvalue{"$venue"}{"$symbol"}     = 0;
        $netcash{"$venue"}{"$symbol"}         = 0;
        $pnl{"$venue"}{"$symbol"}             = 0;
    }

    ### Assigning the most recent trade price to lastprice variable while also calculating the volume traded and dollar amountS
    $lastprice{"$venue"}{"$symbol"}        = $printprice;
    $vlmtraded{"$venue"}{"$symbol"}       += $executed;
    $dollarvlmtraded{"$venue"}{"$symbol"} += ($executed * $printprice);
    
    ### If trade is passive increase vlm passive and vice verse for active.
    if (is_passive_trade($liquidity, $venue)) {
        $vlmpassive{"$venue"}{"$symbol"} += $executed;
    } else {
        $vlmactive{"$venue"}{"$symbol"}  += $executed;
    }


    ### Calculating the net position and cash for each symbol based on whether the trade was a buy or sell
    if ($side eq 'BUY') {
        $netpos{"$venue"}{"$symbol"}  += $executed;     
        $netcash{"$venue"}{"$symbol"} -= ($executed * $printprice);
    } elsif ($side eq 'SELL') {
        $netpos{"$venue"}{"$symbol"}  -= $executed;
        $netcash{"$venue"}{"$symbol"} += ($executed * $printprice);
    }
  
}

### Outputing all the calculated data to standard output as well as calculating the pnl and net position value for each symbol
foreach my $venue (sort keys %lastprice) {
    foreach my $symbol (sort keys %{$lastprice{$venue}}) {

        $netposvalue{"$venue"}{"$symbol"} = $netpos{"$venue"}{"$symbol"} * $lastprice{"$venue"}{"$symbol"};
        $pnl{"$venue"}{"$symbol"} = $netposvalue{"$venue"}{"$symbol"} + $netcash{"$venue"}{"$symbol"};

        print sprintf ("%3s,%10s,%10.2f,% 10.2f,% 10.2f,% 10.2f,% 10.2f,% 10.2f,% 10.2f,% 10.2f\n",
                            $venue,
                            $symbol,
                            $vlmtraded{"$venue"}{"$symbol"},
                            $dollarvlmtraded{"$venue"}{"$symbol"},
                            $vlmpassive{"$venue"}{"$symbol"},
                            $vlmactive{"$venue"}{"$symbol"},
                            $netpos{"$venue"}{"$symbol"},
                            $netposvalue{"$venue"}{"$symbol"},
                            $netcash{"$venue"}{"$symbol"},
                            $pnl{"$venue"}{"$symbol"});
    }
}

sub is_passive_trade {
    my ($liquidity, $venue) = @_;
    my $returnval;

    ### Calculating the colume of active and passive trades based on the liquidity
    if ($venue eq 'CA') {
        my $tradetype = substr $liquidity, 2, 1;
        $returnval = ($tradetype eq 'P');
    } elsif ($venue eq 'US') {
        $returnval = ($liquidity eq 'A');
    } else {
        $returnval = 0;
    }
    return $tradetype;
}

exit(0);

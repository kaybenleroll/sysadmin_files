#!/usr/bin/perl -w

use strict;
use warnings;


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



    print "$venue,$symbol,$vlmtraded,$dollarvlmtraded,$vlmpassive,$vlmactive,$netpos,$netposvalue,$netcash,$pnl\n";

}


exit(0);

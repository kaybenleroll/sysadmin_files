#!/usr/bin/perl -w

use strict;
use warnings;

#use Time::ParseDate;
use Date::Manip;

#Declaration of variables
my %orderdata;

my $timestamp;
my $epoch = 0;


while(my $line = <>) {
    #If the line is an orderupdate inserts the information into the data array and assigns data to their respective variables
    if ($line =~ /.*OrderUpdate\((.*)\)/){
        
        my @data = split(",", $1);

        my $orderid      = $data[0];
        my $symbol       = $data[1];
        my $side         = $data[3];
        my $quantity     = $data[5];
        my $qtyExecuted  = $data[14];
        my $qtyRemaining = $data[15];
        my $lastShares   = $data[16];
        my $lastPrice    = $data[17];
        my $price        = $data[18];
        my $status       = $data[19];

        #Pulls timestamp from line and assigns it to variable
        $line =~ /^(.*?) CRIT/;
        $timestamp = $1;

        #If a timstamp was pulled convert it to epoch for
        my $datemanip = ParseDate($timestamp);
        my $epoch     = UnixDate($datemanip, "%s");

        #Makes sure that the order is a trade by checking orderif and status
        next unless $orderid =~ /^"[^_]/;
        next unless $qtyExecuted > 0;
        next unless ($orderid && $orderid ne "\"\""); 


        #Removes quatations from symbol and side
        $symbol =~ s/"//g;
        $side   =~ s/"//g;

        $side = ($side =~ /SELL/) ? "SELL" : "BUY";

        my $venue;

        #Assigns the venue based on line content
        if($line =~ /TSX_TRADING/) {
            $venue = "CA";
        } elsif($line =~ /TORC_TRADING/) {
            $venue = "US";
        } elsif($line =~ /CURRENEX_TRADING/) {
            $venue = "CNX";
        } else {
            print "Error parsing entry $line";
        }

        #Rounds the price to 6 decimal places
        my $printprice = sprintf("%8.6f", $price);

        if((($qtyExecuted > 0) and ($qtyRemaining == 0)) or ($orderdata{"$orderid"}{'qtyExecuted'} and $qtyExecuted > $orderdata{"$orderid"}{'qtyExecuted'})) {
            print "$venue,$symbol,$side,$lastShares,$qtyRemaining,$lastPrice,$orderid,$timestamp,$epoch,$quantity,$qtyExecuted\n";
        } else {
            $orderdata{"$orderid"}{'qtyExecuted'} = $qtyExecuted;
        }
    }
}

exit(0);


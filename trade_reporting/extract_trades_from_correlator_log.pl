#!/usr/bin/perl -w

use strict;
use warnings;

#use Time::ParseDate;
use Date::Manip;

#Declaration of variables
my %orderdata;

my $timestamp;
my $epoch = 0;


### TODO [mcooney] At moment fill and partial fill updates are identified via FIX tags,
### so the assumption is that the OMS communication is done via FIX. It may be necessary
### to change this in the future.

while(my $line = <>) {
    next if $line =~ /com\.jacobsecurities\.oms/;

    ## If the line is an orderupdate inserts the information into the data array and assigns data to their respective variables
    if ($line =~ /.*OrderUpdate\((.*),\{(.*)\}\)/){

        my %extraParams = ();

        my @data = split(',', $1);
        my $extraParamsString = $2;

        foreach my $datum (split(",", $extraParamsString)) {
            $datum =~ /\"(.*)\":\"(.*)\"/;

            $extraParams{"$1"} = $2;
        }

        my $orderid       = $data[0];
        my $symbol        = $data[1];
        my $side          = $data[3];
        my $marketorderid = $data[13];
        my $qtyRemaining  = $data[15];
        my $lastShares    = $data[16];
        my $lastPrice     = $data[17];
        my $price         = $data[18];

        ## Makes sure that the order is a trade by checking orderid and status
        next unless $orderid =~ /^\"[^_]/;
        next unless ($orderid and $orderid ne '""');
        next unless defined $extraParams{'ExecType'};
        next unless (($extraParams{'ExecType'} eq '1') or ($extraParams{'ExecType'} eq '2'));

        ## Pulls timestamp from line and assigns it to variable
        $line =~ /^(.*?) CRIT/;
        $timestamp = $1;

        ## If a timstamp was pulled convert it to epoch for
        my $datemanip = ParseDate($timestamp);
        my $epoch     = UnixDate($datemanip, "%s");

        ## Removes quatations from entries
        $orderid       =~ s/"//g;
        $marketorderid =~ s/"//g;
        $symbol        =~ s/"//g;
        $side          =~ s/"//g;

        $side = ($side =~ /SELL/) ? "SELL" : "BUY";

        my $venue;

        ## Assigns the venue based on line content
        if($line =~ /TSX_TRADING/) {
            $venue = "CA";
        } elsif($line =~ /TORC_TRADING/) {
            $venue = "US";
        } elsif($line =~ /CURRENEX_TRADING/) {
            $venue = "CNX";
        } else {
            print "Error parsing entry $line";
        }

        ## Rounds the price to 6 decimal places
        my $printprice = sprintf("%8.6f", $price);

        print "CORR,$venue,$symbol,$side,$lastShares,$lastPrice,$orderid,$marketorderid,$timestamp\n";
    }
}

exit(0);

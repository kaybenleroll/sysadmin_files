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

        my $orderid   = $data[0];
        my $symbol    = $data[1];
        my $side      = $data[3];
        my $executed  = $data[14];
        my $remaining = $data[15];
        my $price     = $data[18];
        my $status    = $data[19];

        #Pulls timestamp from line and assigns it to variable
        $line =~ /^(.*?) CRIT/;
        $timestamp = $1;

        #If a timstamp was pulled convert it to epoch for
        my $datemanip = ParseDate($timestamp);
        my $epoch     = UnixDate($datemanip, "%s");

        #Makes sure that the order is a trade by checking orderif and status
        next unless $orderid =~ /^"[^_]/;
        next unless $status  =~ /Filled:/;
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

        #Assigns the information to a hash with the orderid as a key so that if an order is repeated it will no be printed out twice
        $orderdata{"$orderid"}{'value'}     = "$venue,$symbol,$side,$executed,$remaining,$printprice,$orderid,$timestamp,$epoch";
        $orderdata{"$orderid"}{'timestamp'} = "$timestamp";
    }
}

# Prints out every entry in the hash
foreach my $key (sort { $orderdata{$a}{'timestamp'} cmp $orderdata{$b}{'timestamp'} } keys %orderdata) {
    print $orderdata{"$key"}{'value'} . "\n";
}

exit(0);


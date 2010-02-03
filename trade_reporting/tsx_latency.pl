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
    if ($line =~ /.*com.apama.fix.NewOrderSingle\((.*)\)/){
        
        my @data = split(",", $1);

        my $fixorderid   = $data[3];
        my $symbol       = $data[5];
        my $action       = "NewOrderSingle";

        #Pulls timestamp from line and assigns it to variable
        $line =~ /^(.*?) WARN/;
        $timestamp    = $1;

        #If a timstamp was pulled convert it to epoch for
        my $datemanip = ParseDate($timestamp);
        my $epoch     = UnixDate($datemanip, "%s"); 

        #Removes quatations from symbol and side
        $fixorderid =~ s/"//g;
        $symbol     =~ s/"//g;

        #Assigns the information to a hash with the orderid as a key so that if an order is repeated it will no be printed out twice
        $orderdata{"$fixorderid"}{'fixorderid'}     = $fixorderid;
        $orderdata{"$fixorderid"}{'symbol'}         = $symbol;
        $orderdata{"$fixorderid"}{'actiom'}         = $action;
        $orderdata{"$fixorderid"}{'timestamp'}      = $timestamp;

    } elsif ($line =~ /.*com.apama.fix.OrderCancelReplaceRequest\((.*)\)/){

        
        my @data = split(",", $1);

        my $fixorderid   = $data[4];
        my $symbol       = $data[7];
        my $tsxorderid   = $data[2];
        my $action       = "OrderCancelReplaceRequest";

        #Pulls timestamp from line and assigns it to variable
        $line =~ /^(.*?) WARN/;
        $timestamp    = $1;

        #If a timstamp was pulled convert it to epoch for
        my $datemanip = ParseDate($timestamp);
        my $epoch     = UnixDate($datemanip, "%s");

        $fixorderid =~ s/"//g;
        $symbol     =~ s/"//g;  
        $tsxorderid =~ s/"//g;

        $orderdata{"$fixorderid"}{'fixorderid'}     = $fixorderid;
        $orderdata{"$fixorderid"}{'tsxorderid'}     = $tsxorderid;
        $orderdata{"$fixorderid"}{'symbol'}         = $symbol;
        $orderdata{"$fixorderid"}{'actiom'}         = $action;
        $orderdata{"$fixorderid"}{'timestamp'}      = $epoch;

    } elsif ($line =~ /.*com.apama.fix.ExecutionReport\((.*)\)/){

        
        my @data = split(",", $1);

        my $fixorderid   = $data[3];
        my $symbol       = $data[10];
        my $tsxorderid   = $data[2];

        #Pulls timestamp from line and assigns it to variable
        $line =~ /^(.*?) WARN/;
        $timestamp    = $1;

        #If a timstamp was pulled convert it to epoch for
        my $datemanip = ParseDate($timestamp);
        my $epoch     = UnixDate($datemanip, "%s");

        $fixorderid =~ s/"//g;
        $symbol     =~ s/"//g;
        $tsxorderid =~ s/"//g;

        $orderdata{"$fixorderid"}{'latency'}         = $orderdata{"$fixorderid"}{'latency'}

    }

}

# Prints out every entry in the hash
foreach my $key (sort { $orderdata{$a}{'timestamp'} cmp $orderdata{$b}{'timestamp'} } keys %orderdata) {
    print $orderdata{"$key"}{'value'} . "\n";
}

exit(0);


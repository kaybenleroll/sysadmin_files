#!/usr/bin/perl -w -W

use strict;
use warnings;
use diagnostics;

#use Time::ParseDate;
use Date::Manip;

#Declaration of variables
my %orderdata;

my $fixorderid;
my $exchorderid;
my $symbol;
my $action;

my $execType;
my $ordStatus;

my $ms;
my $timestamp;
my $epoch = 0;

my $status = '';


while(my $line = <>) {
    chomp($line);
    
    #If the line is an orderupdate inserts the information into the data array and assigns data to their respective variables
    if($line =~ /.*com.apama.fix.NewOrderSingle\((.*)\)/) {        
        my @data = split(",", $1);

        $fixorderid   = $data[2];
        $symbol       = $data[5];
        $action       = 'NewOrderSingle';
        $status       = '';

        #Pulls timestamp from line and assigns it to variable
        $line =~ /^(.*?) WARN/;
        $timestamp    = $1;
        
        $timestamp =~ /\.(\d\d\d)$/;
        $ms = $1 / 1000;

        #If a timstamp was pulled convert it to epoch for
        my $datemanip = ParseDate($timestamp);
        my $epoch     = UnixDate($datemanip, "%s") + $ms;

        #Removes quatations from symbol and side
        $fixorderid =~ s/"//g;
        $symbol     =~ s/"//g;

        #Assigns the information to a hash with the orderid as a key so that if an order is repeated it will not be printed out twice
        $orderdata{"$fixorderid"}{"$action"}{'fixorderid'}     = $fixorderid;
        $orderdata{"$fixorderid"}{"$action"}{'exchorderid'}    = '';
        $orderdata{"$fixorderid"}{"$action"}{'symbol'}         = $symbol;
        $orderdata{"$fixorderid"}{"$action"}{'timestamp'}      = $timestamp;
        $orderdata{"$fixorderid"}{"$action"}{'epochtime'}      = $epoch;
        $orderdata{"$fixorderid"}{"$action"}{'latency'}        = -1;
        $orderdata{"$fixorderid"}{"$action"}{'adapterlatency'} = 0;

        my $value = sprintf("ERROR:  %s,%s,%s,,%s,%6.4f\n", $orderdata{"$fixorderid"}{"$action"}{'symbol'},
                                                            $action,
                                                            $orderdata{"$fixorderid"}{"$action"}{'timestamp'},
                                                            $orderdata{"$fixorderid"}{"$action"}{'fixorderid'},
                                                            $orderdata{"$fixorderid"}{"$action"}{'epochtime'});
                                                         
        $orderdata{"$fixorderid"}{'$action'}{'value'} = $value;

    } elsif($line =~ /.*com.apama.fix.OrderCancelReplaceRequest\((.*)\)/) {
        my @data = split(",", $1);

        $exchorderid   = $data[2];
        $fixorderid   = $data[4];
        $symbol       = $data[7];
        $action       = 'OrderCancelReplaceRequest';
        $status       = '';

        #Pulls timestamp from line and assigns it to variable
        $line =~ /^(.*?) WARN/;
        $timestamp    = $1;
        
        $timestamp =~ /\.(\d\d\d)$/;
        $ms = $1 / 1000;

        #If a timstamp was pulled convert it to epoch for
        my $datemanip = ParseDate($timestamp);
        my $epoch     = UnixDate($datemanip, "%s") + $ms;

        $fixorderid =~ s/"//g;
        $symbol     =~ s/"//g;  
        $exchorderid =~ s/"//g;

        $orderdata{"$fixorderid"}{"$action"}{'fixorderid'}  = $fixorderid;
        $orderdata{"$fixorderid"}{"$action"}{'exchorderid'} = $exchorderid;
        $orderdata{"$fixorderid"}{"$action"}{'symbol'}      = $symbol;
        $orderdata{"$fixorderid"}{"$action"}{'timestamp'}   = $timestamp;
        $orderdata{"$fixorderid"}{"$action"}{'epochtime'}   = $epoch;
        $orderdata{"$fixorderid"}{"$action"}{'latency'}     = -1;
        $orderdata{"$fixorderid"}{"$action"}{'adapterlatency'} = 0;

        my $value = sprintf("ERROR:  %s,%s,%s,%s,%s,%6.4f\n", $orderdata{"$fixorderid"}{"$action"}{'symbol'},
                                                              $action,
                                                              $orderdata{"$fixorderid"}{"$action"}{'timestamp'},
                                                              $orderdata{"$fixorderid"}{"$action"}{'exchorderid'},
                                                              $orderdata{"$fixorderid"}{"$action"}{'fixorderid'},
                                                              $orderdata{"$fixorderid"}{"$action"}{'epochtime'});

        $orderdata{"$fixorderid"}{"$action"}{'value'} = $value;

    } elsif($line =~ /.*com.apama.fix.ExecutionReport\(\"(.*),\{(.*)\}\)/) {
        my @data = split('","', $1);

        $exchorderid   = $data[2];
        $fixorderid   = $data[3];
        $execType     = $data[7];
        $ordStatus    = $data[8];
        $symbol       = $data[10];

        next unless(($execType eq '0') or ($execType eq '5') or ($execType eq 'E'));

        if($execType eq '0') {
            $action = 'NewOrderSingle';
        } else {
            $action = 'OrderCancelReplaceRequest';
        }

        next if(($action eq 'OrderCancelReplaceRequest') and ($ordStatus eq 'E'));

        if($ordStatus eq '5') {
            $status = 'Replaced';
        } else {
            $status = 'New';
        }
 
        #Pulls timestamp from line and assigns it to variable
        $line =~ /^(.*?) WARN/;
        $timestamp    = $1;

        $timestamp =~ /\.(\d\d\d)$/;
        $ms = $1 / 1000;

        #If a timstamp was pulled convert it to epoch for
        my $datemanip = ParseDate($timestamp);
        my $epoch     = UnixDate($datemanip, "%s") + $ms;

        $fixorderid =~ s/"//g;
        $symbol     =~ s/"//g;
        $exchorderid =~ s/"//g;

        $orderdata{"$fixorderid"}{"$action"}{'latency'}     = $epoch - $orderdata{"$fixorderid"}{"$action"}{'epochtime'};
        $orderdata{"$fixorderid"}{"$action"}{'exchorderid'} = $exchorderid;

        my $value = sprintf("LATENCY,%s,%s,%s,%s,%s,%s,%5.3f,%5.3f",
                            $orderdata{"$fixorderid"}{"$action"}{'symbol'},
                            $action,
                            $status,
                            $orderdata{"$fixorderid"}{"$action"}{'timestamp'},
                            $orderdata{"$fixorderid"}{"$action"}{'exchorderid'},
                            $orderdata{"$fixorderid"}{"$action"}{'fixorderid'},
                            $orderdata{"$fixorderid"}{"$action"}{'adapterlatency'},
                            $orderdata{"$fixorderid"}{"$action"}{'latency'});

        $orderdata{"$fixorderid"}{'value'} = $value;

        print $orderdata{"$fixorderid"}{'value'} . "\n";

    } elsif($line =~ /Round-trip.* = (.*)/) {
        
        
        my $adapter_latency = $1;

        $orderdata{"$fixorderid"}{"$action"}{'adapterlatency'} += $adapter_latency;        
    }

}

exit(0);


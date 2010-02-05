#!/usr/bin/perl -w

use strict;
use warnings;

#use Time::ParseDate;
use Date::Manip;

#Declaration of variables
my %orderdata;

my $ms;
my $timestamp;
my $epoch = 0;


while(my $line = <>) {
    chomp($line);

    
    #If the line is an orderupdate inserts the information into the data array and assigns data to their respective variables
    if ($line =~ /.*com.apama.fix.NewOrderSingle\((.*)\)/){        
        my @data = split(",", $1);

        my $fixorderid   = $data[2];
        my $symbol       = $data[5];
        my $action       = 'NewOrderSingle';

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
        $orderdata{"$fixorderid"}{"$action"}{'fixorderid'} = $fixorderid;
        $orderdata{"$fixorderid"}{"$action"}{'symbol'}     = $symbol;
        $orderdata{"$fixorderid"}{"$action"}{'timestamp'}  = $timestamp;
        $orderdata{"$fixorderid"}{"$action"}{'epochtime'}  = $epoch;

        my $value = sprintf("ERROR:  %s,%s,%s,,%s,%6.4f\n", $orderdata{"$fixorderid"}{"$action"}{'symbol'},
                                                            $action,
                                                            $orderdata{"$fixorderid"}{"$action"}{'timestamp'},
                                                            $orderdata{"$fixorderid"}{"$action"}{'fixorderid'},
                                                            $orderdata{"$fixorderid"}{"$action"}{'epochtime'});
                                                         
        $orderdata{"$fixorderid"}{'$action'}{'value'} = $value;

    } elsif ($line =~ /.*com.apama.fix.OrderCancelReplaceRequest\((.*)\)/){
        my @data = split(",", $1);

        my $tsxorderid   = $data[2];
        my $fixorderid   = $data[4];
        my $symbol       = $data[7];
        my $action       = 'OrderCancelReplaceRequest';

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
        $tsxorderid =~ s/"//g;

        $orderdata{"$fixorderid"}{"$action"}{'fixorderid'} = $fixorderid;
        $orderdata{"$fixorderid"}{"$action"}{'tsxorderid'} = $tsxorderid;
        $orderdata{"$fixorderid"}{"$action"}{'symbol'}     = $symbol;
        $orderdata{"$fixorderid"}{"$action"}{'timestamp'}  = $timestamp;
        $orderdata{"$fixorderid"}{"$action"}{'epochtime'}  = $epoch;

        my $value = sprintf("ERROR:  %s,%s,%s,%s,%s,%6.4f\n", $orderdata{"$fixorderid"}{"$action"}{'symbol'},
                                                              $action,
                                                              $orderdata{"$fixorderid"}{"$action"}{'timestamp'},
                                                              $orderdata{"$fixorderid"}{"$action"}{'tsxorderid'},
                                                              $orderdata{"$fixorderid"}{"$action"}{'fixorderid'},
                                                              $orderdata{"$fixorderid"}{"$action"}{'epochtime'});

        $orderdata{"$fixorderid"}{"$action"}{'value'} = $value;

    } elsif ($line =~ /.*com.apama.fix.ExecutionReport\((.*)\)/){
        my @data = split(",", $1);

        my $tsxorderid   = $data[2];
        my $fixorderid   = $data[3];
        my $execType     = $data[7];
        my $ordStatus    = $data[8];
        my $symbol       = $data[10];

        my $status = '';
        my $action = '';

        if($execType eq '0') {
            $action = 'NewOrderSingle';
        } elsif(($execType eq 'E') or ($execType eq '5')) {
            $action = 'OrderCancelReplaceRequest';
        }

        if($ordStatus eq 'E') {
            $status = 'Pending';            
        } elsif($ordStatus eq '5') {
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
        $tsxorderid =~ s/"//g;

        $orderdata{"$fixorderid"}{"$action"}{'latency'}    = $epoch - $orderdata{"$fixorderid"}{"$action"}{'epochtime'};
        $orderdata{"$fixorderid"}{"$action"}{'tsxorderid'} = $orderdata{"$fixorderid"}{"$action"}{'tsxorderid'} ? $orderdata{"$fixorderid"}{"$action"}{'tsxorderid'} : '';

        my $value = sprintf("LATENCY: %s,%s,%s,%s,%s,%s,%5.3f", $orderdata{"$fixorderid"}{"$action"}{'symbol'},
                                                                $action,
                                                                $status,
                                                                $orderdata{"$fixorderid"}{"$action"}{'timestamp'},
                                                                $orderdata{"$fixorderid"}{"$action"}{'tsxorderid'},
                                                                $orderdata{"$fixorderid"}{"$action"}{'fixorderid'},
                                                                $orderdata{"$fixorderid"}{"$action"}{'latency'});

        $orderdata{"$fixorderid"}{'value'} = $value;

        print $orderdata{"$fixorderid"}{'value'} . "\n";

#        delete $orderdata{"$fixorderid"};
    }

}

exit(0);


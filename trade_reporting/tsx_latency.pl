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
        $orderdata{"$fixorderid"}{'fixorderid'}     = $fixorderid;
        $orderdata{"$fixorderid"}{'symbol'}         = $symbol;
        $orderdata{"$fixorderid"}{'action'}         = $action;
        $orderdata{"$fixorderid"}{'timestamp'}      = $timestamp;
        $orderdata{"$fixorderid"}{'epochtime'}      = $epoch;

        $orderdata{"$fixorderid"}{'value'}          = sprintf("ERROR:  %s,%s,%s,,%s,%6.4f\n",
                                                              $orderdata{"$fixorderid"}{'symbol'},
                                                              $orderdata{"$fixorderid"}{'action'},
                                                              $orderdata{"$fixorderid"}{'timestamp'},
                                                              $orderdata{"$fixorderid"}{'fixorderid'},
                                                              $orderdata{"$fixorderid"}{'epochtime'});

    } elsif ($line =~ /.*com.apama.fix.OrderCancelReplaceRequest\((.*)\)/){
        my @data = split(",", $1);

        my $fixorderid   = $data[4];
        my $symbol       = $data[7];
        my $tsxorderid   = $data[2];
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

        $orderdata{"$fixorderid"}{'fixorderid'}     = $fixorderid;
        $orderdata{"$fixorderid"}{'tsxorderid'}     = $tsxorderid;
        $orderdata{"$fixorderid"}{'symbol'}         = $symbol;
        $orderdata{"$fixorderid"}{'action'}         = $action;
        $orderdata{"$fixorderid"}{'timestamp'}      = $timestamp;
        $orderdata{"$fixorderid"}{'epochtime'}      = $epoch;

        $orderdata{"$fixorderid"}{'value'}          = sprintf("ERROR:  %s,%s,%s,%s,%s,%6.4f\n",
                                                              $orderdata{"$fixorderid"}{'symbol'},
                                                              $orderdata{"$fixorderid"}{'action'},
                                                              $orderdata{"$fixorderid"}{'timestamp'},
                                                              $orderdata{"$fixorderid"}{'tsxorderid'},
                                                              $orderdata{"$fixorderid"}{'fixorderid'},
                                                              $orderdata{"$fixorderid"}{'epochtime'});

    } elsif ($line =~ /.*com.apama.fix.ExecutionReport\((.*)\)/){
        my @data = split(",", $1);

        my $tsxorderid   = $data[2];
        my $fixorderid   = $data[3];
        my $symbol       = $data[10];

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

        $orderdata{"$fixorderid"}{'latency'}    = $epoch - $orderdata{"$fixorderid"}{'epochtime'};
        $orderdata{"$fixorderid"}{'tsxorderid'} = $orderdata{"$fixorderid"}{'tsxorderid'} ? $orderdata{"$fixorderid"}{'tsxorderid'} : '';
        
        $orderdata{"$fixorderid"}{'value'}   = sprintf("LATENCY: %s,%s,%s,%s,%s,%5.3f",
                                                       $orderdata{"$fixorderid"}{'symbol'},
                                                       $orderdata{"$fixorderid"}{'action'},
                                                       $orderdata{"$fixorderid"}{'timestamp'},
                                                       $orderdata{"$fixorderid"}{'tsxorderid'},
                                                       $orderdata{"$fixorderid"}{'fixorderid'},
                                                       $orderdata{"$fixorderid"}{'latency'});
                                                       
        print $orderdata{"$fixorderid"}{'value'} . "\n";
        
#        delete $orderdata{"$fixorderid"};
    }

}

# Prints out every entry in the hash
#foreach my $key (sort { $orderdata{$a}{'fixorderid'} cmp $orderdata{$b}{'fixorderid'} } keys %orderdata) {
#    print $orderdata{"$key"}{'value'} . "\n";
#}

exit(0);


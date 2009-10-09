#!/usr/bin/perl -w

use strict;

while(<>) {
#    chomp();
    
    /(.*) Timestamp: (.*?) Symbol: (.*?) Last Price: (.*?) Interval Volume: (.*) Interval VWAP: (.*?)\n/;
    
    print "$1,$2,$3,$4,$5,$6\n";
}
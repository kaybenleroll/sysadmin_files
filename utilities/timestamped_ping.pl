#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use Net::Ping;
use Time::HiRes qw(tv_interval gettimeofday);

my $hostname = 'localhost';
my $interval = 1;
my $logname  = '/var/log/activ_pingtimes.log';

GetOptions('hostname=s' => \$hostname,
           'interval=s' => \$interval,
           'logname=s'  => \$logname);
           

open(FILE, ">$logname") or die("Unable to open the logfile $logname for writing\n");

my $ping = Net::Ping->new('icmp');

while(1) {
    my $datestr = `date`;    
    chomp($datestr);
    
    my($timeStart) = [gettimeofday()];
    
    if($ping->ping($hostname, 2)) {
        my($timeElapsed) = tv_interval($timeStart, [gettimeofday()]);
        print FILE sprintf("%s -> %.3f msec\n", $datestr, $timeElapsed * 1000);
    } else {
        my($timeElapsed) = tv_interval($timeStart, [gettimeofday()]);
        print FILE sprintf("%s -> %.3f\n", $datestr, $timeElapsed * 1000);
    }
    
    sleep($interval);
}

#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Net::FTP;
use Date::Manip;

my $today;
my $date;
my $tstamp;
my $err;

$today  = UnixDate(ParseDate('today'), "%Y%m%d");
$date   = UnixDate(ParseDate('May 8th, 2009'), "%Y%m%d");
$tstamp = UnixDate(ParseDate($date), "%m%d");

while ($date != $today){

    if (-e "/var/jsi/apama/logfiles/apamalogs_${date}.tar.bz2") {
        chdir "/var/jsi/atalogs";
        system("tar xvjpf /var/jsi/apama/logfiles/apamalogs_${date}.tar.bz2 --wildcards ./*correlator_${date}* ");
        chdir "/var/jsi/tradefile_pnl/test";
        system("cat /var/jsi/atalogs/*correlator_${date}* | grep OrderUpdate | perl /var/jsi/tradefile_pnl/process_fills.pl > trades_${date}.csv");   
    }
    
    $date   = DateCalc($date,"+ 1 days",\$err);
    $date   = UnixDate(ParseDate($date), "%Y%m%d");
    $tstamp = UnixDate(ParseDate($date), "%m%d");

}

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
my $some_dir = "/var/jsi/atalogs/";
my @array;
my $count = 0;

$today  = UnixDate(ParseDate('today'), "%Y%m%d");
$today  = DateCalc($today,"+ 1 days",\$err);
$today  = UnixDate(ParseDate($today), "%Y%m%d");
$date   = UnixDate(ParseDate('May 8th, 2009'), "%Y%m%d");
$tstamp = UnixDate(ParseDate($date), "%m%d");


while ($date != $today){

    if (-e "/var/jsi/apama/logfiles/apamalogs_${date}.tar.bz2") {
        chdir "/var/jsi/tradefile_pnl";
        system("cat /var/jsi/atalogs/*correlator_${date}* | grep OrderUpdate | perl /var/jsi/tradefile_pnl/process_fills.pl > trades_${date}.csv");   
        system("cat /var/jsi/tradefile_pnl/trades_${date}.csv | grep -v HTC | perl /var/jsi/tradefile_pnl/calculate_pnl.pl > pnl_${date}.csv");
        $array[$count] = "/var/jsi/atalogs/*correlator_${date}* ";
        $count = $count + 1;
        system("cat @array | grep OrderUpdate | perl process_fills.pl | perl calculate_pnl.pl > cumlpnl_${date}.csv");
    }

    $date   = DateCalc($date,"+ 1 days",\$err);
    $date   = UnixDate(ParseDate($date), "%Y%m%d");
    $tstamp = UnixDate(ParseDate($date), "%m%d");

}

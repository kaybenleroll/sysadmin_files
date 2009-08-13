#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Net::FTP;
use Date::Manip;

#Declaration of variables
my $today;
my $date;
my $tstamp;
my $err;
my @array;
my @array2;
my $count = 0;
my $count2 = 0;

#Initialize and format today date and tstamp variables
$today  = UnixDate(ParseDate('today'), "%Y%m%d");
$today  = DateCalc($today,"+ 1 days",\$err);
$today  = UnixDate(ParseDate($today), "%Y%m%d");
$date   = UnixDate(ParseDate('June 18th, 2009'), "%Y%m%d");
$tstamp = UnixDate(ParseDate($date), "%m%d");

#Set the workign directory to tradefile_pnl
chdir "/var/jsi/tradefile_pnl";

#Continue to run code until the date hits today
while ($date != $today){

    #Run code is there exists an apamalogs for given date
    if (-e "/var/jsi/apama/logfiles/apamalogs_${date}.tar.bz2") {
        # If there exists a corrections file for the given day include it in system calls otherwise do not
        if (-e "/var/jsi/tradefile_pnl/corrections/corrections_${date}.csv"){
            #Create trades file by cating the correlator files for the day through process fills
            #Create pnl file by cating newly created tradefile and corrections file through calculate pnl filtering out and HTC trades
            system("cat /var/jsi/atalogs/*correlator_${date}* | grep OrderUpdate | perl process_fills.pl > /var/jsi/tradefile_pnl/trades/trades_${date}.csv");   
            system("cat /var/jsi/tradefile_pnl/trades/trades_${date}.csv /var/jsi/tradefile_pnl/corrections/corrections_${date}.csv | grep -v HTC | perl calculate_pnl.pl > /var/jsi/tradefile_pnl/pnl/pnl_${date}.csv");
            #Add the trades file and corrections to their respective arrays and increase their array counters
            $array[$count] = "/var/jsi/tradefile_pnl/trades/trades_${date}.csv ";
            $array2[$count2] = "/var/jsi/tradefile_pnl/corrections/corrections_${date}.csv";
            $count = $count + 1;
            $count2 = $count2 + 1;
            #Cat all previous trade files and corrections files through calculate_pnl to create cumlpnl file
            system("cat @array @array2 | grep -v HTC | perl calculate_pnl.pl > /var/jsi/tradefile_pnl/cumlpnl/cumlpnl_${date}.csv");
        } else {
            #Executes the same as above except does not cat any corrections files
            system("cat /var/jsi/atalogs/*correlator_${date}* | grep OrderUpdate | perl process_fills.pl > /var/jsi/tradefile_pnl/trades/trades_${date}.csv");   
            system("cat /var/jsi/tradefile_pnl/trades/trades_${date}.csv | grep -v HTC | perl calculate_pnl.pl > /var/jsi/tradefile_pnl/pnl/pnl_${date}.csv");
            $array[$count] = "/var/jsi/tradefile_pnl/trades/trades_${date}.csv ";
            $count = $count + 1;
            system("cat @array @array2 | grep -v HTC | perl calculate_pnl.pl > /var/jsi/tradefile_pnl/cumlpnl/cumlpnl_${date}.csv")            
        }
    }

    #Increases the date by 1 day and reformats the date and tstamp as the addition of one day alters the format
    $date   = DateCalc($date,"+ 1 days",\$err);
    $date   = UnixDate(ParseDate($date), "%Y%m%d");
    $tstamp = UnixDate(ParseDate($date), "%m%d");

}

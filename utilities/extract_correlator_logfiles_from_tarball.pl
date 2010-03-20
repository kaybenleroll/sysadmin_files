#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Date::Manip;

### Declaration of variables
my $today;
my $date;
my $tstamp;
my $err;

my $file_path = '/var/jsi/storage/apama/logfiles';


### Intializes variables and reformats them to their correct format
$today  = UnixDate(ParseDate('today'), "%Y%m%d");
$today  = DateCalc($today,"+ 1 days",\$err);
$today  = UnixDate(ParseDate($today), "%Y%m%d");
$date   = UnixDate(ParseDate('June 18th, 2009'), "%Y%m%d");
$tstamp = UnixDate(ParseDate($date), "%m%d");

### Changes the working directory to atalogs folder
chdir "/var/jsi/atalogs";

### If there exists an apamalog for the given date extract correlator file or files for tar ball
while ($date != $today){
    if (-e "${file_path}/apamalogs_${date}.tar.bz2") {
        system("tar xvjpf ${file_path}/apamalogs_${date}.tar.bz2 --wildcards \"*correlator_${date}*\"");
    }
    
    ### Increase the date by 1 and reformat the date back to correct format. Continue until current date is reached
    $date   = DateCalc($date,"+ 1 days",\$err);
    $date   = UnixDate(ParseDate($date), "%Y%m%d");
    $tstamp = UnixDate(ParseDate($date), "%m%d");
}

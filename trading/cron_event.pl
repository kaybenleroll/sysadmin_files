#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use File::Copy;
use Net::FTP;
use Date::Manip;

#Declare variables and Initialize to their default values
my $date     = 'today';
my $tstamp   = undef;
my $host     = '207.35.239.17';
my $user     = 'F96FTP01';
my $pass     = 'VLZWR3IBK1';

my $ftpcheck;
my $filename;

#Get Options for the file, date and ftp specs
GetOptions('filename=s'   => \$filename,
           'date=s'       => \$date,
           'host=s'       => \$host,
           'user=s'       => \$user,
           'ftp=s'        => \$ftpcheck,
           'password=s'   => \$pass);

#Changes date and time stamp into proper formats
$date        = UnixDate(ParseDate($date), "%Y%m%d");
$tstamp      = UnixDate(ParseDate($date), "%m%d");

#If filename has not been given give default filename
if (!$filename){
    $filename = "/var/jsi/atalogs/ATA_correlator_${date}*";
}

#Uses a sysem call to cat the given file (usually the correlator file) through process fills and into it respective trade file
system("cat $filename | grep OrderUpdate | perl process_fills.pl > trades_${date}.csv");
move("trades_${date}.csv","/var/jsi/tradefile_pnl/trades");

#If a corrections file exists for the given day include cat of corrections file, otherwise do not
#Uses another system call to cat trades files into calculate pnl to create the pnl and cumlpnl for the day
#Then cat's trades files into generate dropfiles
if (-e "/var/jsi/tradefile_pnl/corrections/corrections_${date}.csv"){
    system("cat /var/jsi/tradefile_pnl/trades/trades_${date}.csv /var/jsi/tradefile_pnl/corrections/corrections_${date}.csv | grep -v HTC | perl calculate_pnl.pl > pnl_${date}.csv");
    system("cat /var/jsi/tradefile_pnl/trades/trades_* /var/jsi/tradefile_pnl/corrections/corrections_* |  grep -v HTC | perl calculate_pnl.pl > cumlpnl_${date}.csv");
    system("cat /var/jsi/tradefile_pnl/trades/trades_${date}.csv /var/jsi/tradefile_pnl/corrections/corrections_${date}.csv | perl generate_dropfile.pl");
} else {
    system("cat /var/jsi/tradefile_pnl/trades/trades_${date}.csv | grep -v HTC | perl calculate_pnl.pl > pnl_${date}.csv");
    system("cat /var/jsi/tradefile_pnl/trades/trades_* |  grep -v HTC | perl calculate_pnl.pl > cumlpnl_${date}.csv");
    system("cat /var/jsi/tradefile_pnl/trades/trades_${date}.csv | perl generate_dropfile.pl");
}

#Moves pnl cumlpnl and penson files to their respective folders
move("pnl_${date}.csv","/var/jsi/tradefile_pnl/pnl");
move("cumlpnl_${date}.csv","/var/jsi/tradefile_pnl/cumlpnl");
move("F96TR${tstamp}1.csv", "/var/jsi/pensonfiles/");
move("F96TR${tstamp}2.csv", "/var/jsi/pensonfiles/");

#cat's torcfiles through rollup torc and generatedropfile to create the torc comparison file
system("cat /var/jsi/torcfiles/JacobSecurities_${date} | perl rollup_torc.pl | perl generate_dropfile.pl");

#If Ftp has been enabled through get option, upload files ftp server
chdir "/var/jsi/pensonfiles/";
if ($ftpcheck){
    my $ftp_h = Net::FTP->new($host, Debug => 0);
    $ftp_h->login($user, $pass);
    $ftp_h->cwd("/eod");
    $ftp_h->put("F96TR${tstamp}1.csv");
    $ftp_h->put("F96TR${tstamp}2.csv");
}

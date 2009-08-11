#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use File::Copy;
use Net::FTP;
use Date::Manip;

my $date     = 'today';
my $tstamp   = undef;
my $host     = '207.35.239.17';
my $user     = 'F96FTP01';
my $pass     = 'VLZWR3IBK1';

my $filename;

GetOptions('filename=s'   => \$filename,
           'date=s'       => \$date,
           'host=s'       => \$host,
           'user=s'       => \$user,
           'password=s'   => \$pass);

$date        = UnixDate(ParseDate($date), "%Y%m%d");
$tstamp      = UnixDate(ParseDate($date), "%m%d");

$filename = "/var/jsi/atalogs/ATA_correlator_${date}*";

system("cat $filename | grep OrderUpdate | perl process_fills.pl > trades_${date}.csv");

if (-e "/var/jsi/tradefile_pnl/corrections/corrections_${date}.csv"){
    system("cat trades_${date}.csv /var/jsi/tradefile_pnl/corrections/corrections_${date}.csv | grep -v HTC | perl calculate_pnl.pl > pnl_${date}.csv");
    system("cat trades_* /var/jsi/tradefile_pnl/corrections/corrections_* |  grep -v HTC | perl calculate_pnl.pl > cumlpnl_${date}.csv");
    system("cat trades_${date}.csv /var/jsi/tradefile_pnl/corrections/corrections_${date}.csv | perl generate_dropfile.pl");
} else {
    system("cat trades_${date}.csv | grep -v HTC | perl calculate_pnl.pl > pnl_${date}.csv");
    system("cat trades_* |  grep -v HTC | perl calculate_pnl.pl > cumlpnl_${date}.csv");
    system("cat trades_${date}.csv | perl generate_dropfile.pl");
}

move("trades_${date}.csv","/var/jsi/tradefile_pnl/trades");
move("pnl_${date}.csv","/var/jsi/tradefile_pnl/pnl");
move("cumlpnl_${date}.csv","/var/jsi/tradefile_pnl/cumlpnl");
move("F96TR${tstamp}1.csv", "/var/jsi/pensonfiles/");
move("F96TR${tstamp}2.csv", "/var/jsi/pensonfiles/");

system("cat /var/jsi/torcfiles/JacobSecurities_${date} | perl rollup_torc.pl | perl generate_dropfile.pl");

#system("diff F96TR${tstamp}2 /var/jsi/pensonfiles/F96TR${tstamp}2");

#system("rm F96TR${tstamp}2");

#my $ftp_h = Net::FTP->new($host, Debug => 0);
#$ftp_h->login($user, $pass);
#$ftp_h->cwd("/eod");
#$ftp_h->put("F96TR${tstamp}1.csv");
#$ftp_h->put("F96TR${tstamp}2.csv");

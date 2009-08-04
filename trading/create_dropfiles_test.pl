#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Net::FTP;
use Date::Manip;

my $filename = undef;
my $date     = 'today';
my $tstamp   = undef;
my $host     = '207.35.239.17';
my $user     = 'F96FTP01';
my $pass     = 'VLZWR3IBK1';

GetOptions('filename=s'   => \$filename,
           'date=s'       => \$date,
           'host=s'       => \$host,
           'user=s'       => \$user,
           'password=s'   => \$pass);

$date = UnixDate(ParseDate($date), "%Y%m%d");
$tstamp = UnixDate(ParseDate($date), "%m%d");

if ($filename = undef){
    $filename = "/var/jsi/atalogs/ATA_correlator_${date}_*";
}

#system("cat $filename | grep OrderUpdate | perl process_fills.pl > trades_${date}");

#system("cat $filename | grep OrderUpdate | perl process_fills.pl | perl calculate_pnl.pl > pnl_${date}");

#system("cat trades_*  | perl calculate_pnl.pl > cumlpnl_${date}");

#system("cat $filename | grep OrderUpdate | perl process_fills.pl | perl generate_dropfile.pl");

my $ftp_h = Net::FTP->new($host, Debug => 0);

$ftp_h->login($user, $pass);

$ftp_h->cwd("/eod");

$ftp_h->put(F96TR${tstamp}1 [,F96TR${tstamp}1]);

$ftp_h->put(F96TR${tstamp}2 [,F96TR${tstamp}2]);

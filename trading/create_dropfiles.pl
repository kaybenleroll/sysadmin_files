#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Net::FTP;
use Date::Manip;

my $date     = 'today';
my $tstamp   = undef;
my $host     = '207.35.239.17';
my $user     = 'F96FTP01';
my $pass     = 'VLZWR3IBK1';

$date        = UnixDate(ParseDate($date), "%Y%m%d");
$tstamp      = UnixDate(ParseDate($date), "%m%d");

my $filename = "/var/jsi/atalogs/ATA_correlator_${date}*";

GetOptions('filename=s'   => \$filename,
           'date=s'       => \$date,
           'host=s'       => \$host,
           'user=s'       => \$user,
           'password=s'   => \$pass);

system("cat $filename | grep OrderUpdate | perl process_fills.pl > trades_${date}.csv");

system("cat $filename | grep OrderUpdate | perl process_fills.pl | perl calculate_pnl.pl > pnl_${date}.csv");

system("cat trades_*  | perl calculate_pnl.pl > cumlpnl_${date}.csv");

system("cat $filename | grep OrderUpdate | perl process_fills.pl | perl generate_dropfile.pl");


my $ftp_h = Net::FTP->new($host, Debug => 0);
$ftp_h->login($user, $pass);
$ftp_h->cwd("/eod");
$ftp_h->put("F96TR${tstamp}1.csv");
$ftp_h->put("F96TR${tstamp}2.csv");


move("F96TR${tstamp}1.csv", "/var/jsi/pensonfiles/");
move("F96TR${tstamp}2.csv", "/var/jsi/pensonfiles/");


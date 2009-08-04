#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Net::FTP;
use Date::Manip;

my $filename = '';
my $date     = 'today';
my $tstamp   = undef;
my $host     = '';
my $user     = '';
my $pass     = '';

GetOptions('filename=s'   => \$filename,
           'date=s'       => \$date,
           'host=s'       => \$host,
           'user=s'       => \$user,
           'password=s'   => \$pass);

$date = UnixDate(ParseDate($date), "%Y%m%d");
$tstamp = UnixDate(ParseDate($date), "%m%d");

if ($filename = ''){
    $filename = "ATA_correlator_${date}_*";
}

system("cat $filename | grep OrderUpdate | perl process_fills.pl > trades_${date}");

system("cat $filename | grep OrderUpdate | perl process_fills.pl | perl calculate_pnl.pl > pnl_${date}");

system("cat trades_*  | perl calculate_pnl.pl > cumlpnl_${date}");

system("cat $filename | grep OrderUpdate | perl process_fills.pl | perl generate_dropfile.pl");

my $ftp_h = Net::FTP->new($host, Debug => 0);

$ftp_h->login($user, $pass);

$ftp_h->put(F96TR${tstamp}1 [,F96TR${tstamp}1]);

$ftp_h->put(F96TR${tstamp}2 [,F96TR${tstamp}2]);

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

GetOptions('date=s'       => \$date);

$tstamp      = UnixDate(ParseDate($date), "%m%d");

my $ftp_h = Net::FTP->new($host, Debug => 0);
$ftp_h->login($user, $pass);
$ftp_h->cwd("/home/F96FTP01/eod");
$ftp_h->put("F96TR${tstamp}1.csv");
$ftp_h->put("F96TR${tstamp}2.csv");



#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use File::Copy;
use Net::FTP;
use Date::Manip; 

my $date         = 'today';
my $tstamp       = undef;
my $host         = '207.35.239.17';
my $user         = 'F96FTP01';
my $pass         = 'VLZWR3IBK1';
my $download_dir = '/var/jsi/pensonreports';
my $email_addr   = 'testgroup@jacobsecurities.com';


GetOptions('date=s'         => \$date,
           'email_addr=s'   => \$email_addr,
           'download_dir=s' => \$download_dir);

$tstamp      = UnixDate(DateCalc(ParseDate($date),"-1 business day"), "%Y-%m-%d");

print "Downloading timestamp is $tstamp\n";

mkdir("$download_dir/$tstamp");
chdir("$download_dir/$tstamp");


my $ftp_h = Net::FTP->new($host, Debug => 0);
$ftp_h->login($user, $pass);

$ftp_h->cwd("/home/F96FTP01/Reports");

my @full_file_list = $ftp_h->ls();

my @download_list = ();

foreach my $file (@full_file_list) {
    push(@download_list, $file) if $file =~ /$tstamp/;
}

foreach my $file (@download_list) {
    $ftp_h->get($file);
}


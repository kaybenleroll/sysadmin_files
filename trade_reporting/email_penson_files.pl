#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use File::Copy;
use Net::FTP;
use Date::Manip; 
use MIME::Lite;


my $date         = 'today';
my $tstamp       = undef;
my $host         = '207.35.239.17';
my $user         = 'F96FTP01';
my $pass         = 'VLZWR3IBK1';
my $download_dir = '/var/jsi/pensonreports';
my $email_addr   = 'testgroup@jacobsecurities.com';

my $smtp_host    = 'smtp.1and1.com';
my $smtp_user    = 'smtpusers@jacobsecurities.com';
my $smtp_pass    = '98FrCup';

my $target_email = 'dailypensontradingreports@jacobsecurities.com';


GetOptions('date=s'         => \$date,
           'target_email=s' => \$target_email,
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

print "Checking the file list for required files\n";
foreach my $file (@full_file_list) {
    push(@download_list, $file) if $file =~ /$tstamp/;
}

foreach my $file (@download_list) {
    print "Retrieving file $file\n";
    $ftp_h->get($file);
}


my $email_msg = MIME::Lite->new(
    From    => 'no-reply@jacobsecurities.com',
    To      => 'testgroup@jacobsecurities.com',
    Subject => 'Test Files Email',
    Type    => 'TEXT',
    Data    => 'This is a test email'
);


foreach my $file (@download_list) {
    $email_msg->attach(
        Path     => $download_dir . "/$tstamp/$file",
        Filename => $file
    );
}


$email_msg->send('smtp', $smtp_host, AuthUser => $smtp_user, AuthPass => $smtp_pass);

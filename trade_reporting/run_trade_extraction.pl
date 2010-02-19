#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Net::FTP;
use Date::Manip;

my $logfile_dir  = '/var/jsi/common/atalogs';
my $output_dir   = '.';
my $script_dir   = '/home/mcooney/sysadmin/trade_reporting';
my $start_date   = '18-June-2009';
my $end_date     = 'today';

GetOptions('logfile_dir=s'  => \$logfile_dir,
           'output_dir=s'   => \$output_dir,
           'script_dir=s'   => \$script_dir,
           'start_date=s'   => \$start_date,
           'end_date=s'     => \$end_date);

### Initialize and format today date and tstamp variables
my $iter_start = ParseDate($start_date);
my $iter_end   = ParseDate($end_date);

my $iter_date = $iter_start;

while(Date_Cmp($iter_date, $iter_end) <= 0) {
    my $date_string = UnixDate($iter_date, '%Y%m%d');

    my $cmd_string = "cat *correlator*_${date_string}*.log | ${script_dir}/extract_trades_from_correlator_log.pl > trades_${date_string}.csv";
    print "${date_string}\n";
    system($cmd_string);

    $iter_date = DateCalc($iter_date, '+1 business day');
}


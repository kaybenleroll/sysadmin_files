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

my $file_path    = '/var/jsi/storage/apama/logfiles';
my $extract_root = '/var/jsi/tradereporting/fixlogs';

my $start_date   = '18-June-2009';
my $end_date     = 'today';


GetOptions('file_path=s'    => \$file_path,
           'extract_root=s' => \$extract_root,
           'start_date=s'   => \$start_date,
           'end_date=s'     => \$end_date);



### Intializes variables and reformats them to their correct format
my $iter_end  = ParseDate($end_date);
my $iter_date = ParseDate($start_date);


### Changes the working directory to atalogs folder

### If there exists an apamalog for the given date extract correlator file or files for tar ball
while (Date_Cmp($iter_date, $iter_end) <= 0){
    my $datestr = UnixDate($iter_date, '%Y%m%d');

    if (-e "${file_path}/apamalogs_${datestr}.tar.bz2") {
        my $extract_dir = $extract_root . "/$datestr";

        mkdir($extract_dir);

        my $cmd_string = "tar xvjpf ${file_path}/apamalogs_${datestr}.tar.bz2 -C ${extract_dir} --wildcards \"*FIX_Log*\"";
        print $cmd_string . "\n";
        system($cmd_string);
    }

    ### Increase the date by 1 and reformat the date back to correct format. Continue until current date is reached
    $iter_date   = DateCalc($iter_date, "+ 1 days");
}

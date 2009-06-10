#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use File::Copy;
use File::Path;
use Date::Manip;

my $logdir        = undef;
my $storagedir    = undef;
my $t_stamp       = undef;
my $date          = undef;

### create timestamp of date in format YYYYMMDD

$date = ParseDate("today");
$t_stamp = UnixDate($date, "%Y%m%d");

GetOptions('logdir=s'     => \$logdir,
           'storagedir=s' => \$storagedir,
           'timestamp=s'  => \$t_stamp);

### change directory to log directory
chdir "$logdir";

### create compressed file
system("tar cjf apamalogs_${t_stamp}.tar.bz2 . ");
 
### move compressed file to storage location, remove the directory and recreate the directory
move("apamalogs_${t_stamp}.tar.bz2", $storagedir);
rmtree($logdir);
mkpath($logdir);



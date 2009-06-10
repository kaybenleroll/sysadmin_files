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
my $date          = undef;
 
### create timestamp of date in format YYYYMMDD
 
$date = "today";
 
GetOptions('logdir=s'     => \$logdir,
           'storagedir=s' => \$storagedir,
           'date=s'       => \$date);
 
my $t_stamp = UnixDate(ParseDate($date), "%Y%m%d");

### change directory to log directory
chdir "$logdir";

### create compressed file
system("tar cjfp apamalogs_${t_stamp}.tar.bz2 . ");
 
### move compressed file to storage location, remove the directory and recreate the directory
move("apamalogs_${t_stamp}.tar.bz2", $storagedir);
rmtree($logdir);
mkpath($logdir);



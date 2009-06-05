#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use File::Copy;
use File::Path;
use Archive::Tar;

my $logdir = undef;
my $storagedir = undef;
my $t_stamp       = undef;

GetOptions('logdir=s'     => \$logdir,
           'storagedir=s' => \$storagedir,
           'timestamp=s' => \$t_stamp);


chdir "$logdir";

if ($t_stamp = undef){
    $t_stamp = `date`; #load $t_stamp with the date and time
    $t_stamp =~ s/\://g; # remove all colons from time stamp string 
    $t_stamp =~ s/\s+//g; # remove all white sapces from time stamp string 
    #$t_stamp =~ s/ /_/g;  # replaces all white space with underscores
}

system("tar cjf apamalogs_${t_stamp}.tar.bz2 . "); #create compressed file
#@subdir = `ls -R`;
#create_archive("$logdir"."apamalogs_${t_stamp}.tar.bz2",0,glob("*"));
 
move("apamalogs_${t_stamp}.tar.bz2","$storagedir"); #move compressed file to storage location
 
rmtree("$logdir"); #remove the directory that had just been compressed
 
mkpath("$logdir"); #recreate the directory that had just been deleted

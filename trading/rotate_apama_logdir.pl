#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

my $logdir        = "/cygdrive/c/users/john/documents/perl/test";
my $storagedir    = "/cygdrive/c/users/john/documents";
my $t_stamp       = undef;

system("cd $logdir");#move to directory to be compressed

$t_stamp = `date`; #load $t_stamp with the date and time

$t_stamp =~ s/\://g; # remove all colons from time stamp string 
$t_stamp =~ s/\s+//g; # remove all white sapces from time stamp string 
#$t_stamp =~ s/ /_/g;  # replaces all white space with underscores 

system("tar cjf apamalogs_${t_stamp}.tar.bz2 . "); #create compressed file

system("mv apamalogs_${t_stamp}.tar.bz2 $storagedir"); #move compressed file to storage location

system("rm -r $logdir"); #remove the directory that had just been compressed
system("mkdir $logdir"); #recreate the directory that had just been deleted
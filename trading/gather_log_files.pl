#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;


my $file_path = $ARGV[0];

opendir(DIR, $file_path) or die "Can't open directory $file_path\n";
my @list = readdir(DIR);
closedir(DIR);

foreach my $file (@list) {
    next if $file =~ /^\.$/;
    next if $file =~ /^\.\.$/;

    if($file =~ /.*_(2009\d\d\d\d)(_|\.).*/) {
	my $datekey = $1;

	my $directory = "${file_path}/$datekey";

	if(! -d $directory) {
#	    print "Creating $directory\n";
	    mkdir($directory);
        }

        my $oldfile = "${file_path}/$file";
        my $newfile = "${file_path}/$datekey/$file";

        if($datekey) {
	    print "Moving $oldfile to $newfile\n";
	    rename($oldfile, $newfile);
        }
    }
}

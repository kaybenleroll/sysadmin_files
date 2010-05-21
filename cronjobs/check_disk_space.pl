#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Filesys::DiskSpace;

# file system to monitor
my $dir   = "/apama";
my $limit = 20;

GetOptions('dir=s'    => \$dir,
           'limit=s'  => \$limit);


# get df
my ($fs_type, $fs_desc, $used, $avail, $fused, $favail) = df $dir;
my @disk_data = df $dir;

print join(",", @disk_data) . "\n";

# calculate
my $df_free = (($favail) / ($favail+$fused)) * 100.0;

if($favail < ($limit * 1024 * 1024)) {
    print "Less than $limit Gb remaining on drive\n";
} else {
    print "More than $limit Gb remaining on drive\n";
}

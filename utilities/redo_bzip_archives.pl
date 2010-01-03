#!/usr/bin/perl -w

use strict;

my $file = $ARGV[0];

my $stem = $file;
$stem =~ s/\.bz2//g;

my $cmd = "bunzip2 -v $file";
print "$cmd\n";
system($cmd);

$cmd = "pbzip2 -v $stem";
print "$cmd\n";
system($cmd);


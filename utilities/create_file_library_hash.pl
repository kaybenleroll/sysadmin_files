#!/usr/bin/perl -w -W

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use Digest::MD5;

my $dir = '/var/jsi/storage/Library';

GetOptions('dir=s' => \$dir);

opendir(DIR, $dir);

my @files = readdir(DIR);

closedir(DIR);

my $md5calc = Digest::MD5->new();

foreach my $file (@files) {
    my $fullpath = "${dir}/${file}";

    if(-f $fullpath) {
        open(FILE, $fullpath);

        $md5calc->addfile(*FILE);

        print $md5calc->hexdigest() . "," . $fullpath . "\n";
    }
}


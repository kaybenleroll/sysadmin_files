#!/usr/bin/perl -w -W

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use Digest::MD5;

my %deletelist;

my $file = 'hashlist.txt';
my $dir  = '/var/jsi/storage/Library';

GetOptions('dir=s'  => \$dir,
           'file=s' => \$file);

opendir(DIR, $dir);
my @files = readdir(DIR);
closedir(DIR);

open(FILE, $file) or die("Cannot open the hash file $file");

foreach my $line (<FILE>) {
    my ($hash, @data) = split(",", $line);

    $deletelist{"$hash"} = 1;
}


my $md5calc = Digest::MD5->new();

foreach my $file (@files) {
    my $fullpath = "${dir}/${file}";

    if(-f $fullpath) {
        open(FILE, $fullpath);

        binmode(*FILE);

        $md5calc->addfile(*FILE);

        if(exists($deletelist{$md5calc->hexdigest()})) {
            print "Hash of file part of the list, deleting $fullpath\n";
            unlink($fullpath);
        }
    }
}


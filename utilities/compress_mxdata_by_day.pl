#!/usr/bin/perl -w

use strict;


open(FILE, 'datestring.txt');

my @keylist = <FILE>;

while(my $key = shift @keylist) {
    chomp($key);

    my $outfile = 'mxoptiondata_' . $key . '.tar.bz2';

    my $cmd_string = "tar cvfp ${outfile} --use-compress-program /usr/bin/pbzip2 *_${key}.csv";

    print $cmd_string . "\n";
    system($cmd_string);

}



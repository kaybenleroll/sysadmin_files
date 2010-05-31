#!/usr/bin/perl -w

use strict;
use warnings;

### Declaration of variables
my %hash;

my $count = 0;
my $line = <>;
my @symbol = split(",", $line);

while($line = <>) {
    chomp($line);
    my @data = split(",", $line);       
    for($count = 0 ; $count <= $#symbol; $count = $count + 2) {
        $symbol[$count] =~ s/ CN Equity/.TO/;
        $symbol[$count] =~ s/\//\./;
        $symbol[$count] =~ s/-U/u/;
        if ($data[$count]) {
            print "$symbol[$count],$data[$count],$data[$count+1]\n";
        }
    }
}


exit(0);

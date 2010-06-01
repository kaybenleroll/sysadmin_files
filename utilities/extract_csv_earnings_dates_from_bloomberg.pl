#!/usr/bin/perl -w

use strict;
use warnings;
use Date::Manip;

### Declaration of variables
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
            $data[$count] =~ m/(\d+)/g;           
            my $date = $1;
            $data[$count] =~ m/(\d+)/g;           
            $date = $1 . "-" . $date;
            $data[$count] =~ m/(\d+)/g;           
            $date = $1 . "-" .$date;
            print "$symbol[$count],$date,$data[$count+1]\n";
        }
    }
}


exit(0);

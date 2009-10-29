#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Date::Manip;

### Declaration of variables
my $date = "today";
my $filename1;
my $filename2;

my %testhash;

### Get options for two files and date
GetOptions('file1=s'   => \$filename1,
           'file2=s'   => \$filename2,
           'date=s'    => \$date);

### Formats the date
$date        = UnixDate(ParseDate($date), "%Y%m%d");

### Initilizes the filenames if not already initialized
if (!$filename1){
    $filename1 = "trades_test.csv";
}
if (!$filename2){
    $filename2 = "trades/trades_$date.csv";
}

### Opens file, reads the data from the line and adds 1 to the hash for each trade made
open(RFILE, "$filename1") || die ("Could not open file!");

while(my $line = <RFILE>) {
    chomp ($line);
    my ($venue, $symbol, $side, $qty, $remain, $price) = split(",", $line);

    $testhash{$venue}{$symbol}{$side}{$price} += $qty;
}
close(RFILE);

### Opens file, reads the data from the line and subtracts 1 from the hash for each trade made
open(RFILE, "$filename2") || die ("Could not open file!");

while(my $line = <RFILE>) {
    chomp ($line);
    my ($venue, $symbol, $side, $qty, $remain, $price) = split(",", $line);

    $testhash{$venue}{$symbol}{$side}{$price} -= $qty;
}
close(RFILE);

### For each venue, symbol, side, quantity, and price it checks if the hash is equal to 0 (ie trade happens in both files)
### If not it prints out the venue symbol side quantity price and the hash value.
foreach my $venue (sort keys %testhash) {
    foreach my $symbol (sort keys %{ $testhash{"$venue"} }) {
        foreach my $side (sort keys %{ $testhash{"$venue"}{"$symbol"} }) {
            foreach my $price (sort keys %{ $testhash{"$venue"}{"$symbol"}{"$side"} }) {
                if(($testhash{"$venue"}{"$symbol"}{"$side"}{"$price"} != 0) and ($venue ne "CNX")){
                    print sprintf("%s,%s,%s,%d,0,%2.4f\n", $venue, $symbol, $side, $testhash{"$venue"}{"$symbol"}{"$side"}{"$price"}, $price);
                }
            }
        }
    }
}


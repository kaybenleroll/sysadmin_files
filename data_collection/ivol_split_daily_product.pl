#!/usr/bin/perl -w

use strict;

my %datahash;

my $datafile = $ARGV[0];


while( my $line = <> ) {
  chomp($line);
  $line =~ s/\r\n//g;
  $line =~ s/\0//g;

  my @data = split(",", $line);

  my $product = $data[0];
  my $date    = $data[2];

  (my $month, my $day, my $year) = split( "/", $date );

  my $dateformat = sprintf("%04d%02d%02d",$year,$month,$day);

  $datahash{"$product"}{"$dateformat"} .= $line . "\n";
}


foreach my $product (sort keys %datahash) {
  foreach my $date (sort keys %{ $datahash{"$product"} }) {
    my $filename = "ivolatility_${date}_${product}.csv";

    open(FILE,">".$filename) or die("Could not open file " . $filename);

    print FILE $datahash{"$product"}{"$date"};

    close(FILE);
  }
}

exit(0);

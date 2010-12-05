#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Date::Manip;
use Getopt::Long;

my $datafile;
my $outputfile = 'insert.sql';

GetOptions('datafile=s'   => \$datafile,
           'outputfile=s' => \$outputfile);

open(FILE,          $datafile)   or die("Cannot open $datafile\n");
open(OUTFILE, '>' . $outputfile) or die("Cannot write to $outputfile\n");


print OUTFILE "COPY optiondata (name,datatimestamp,expiry,strike,callput,bid,ask,price,impliedvol,volume,openinterest,delta,gamma,vega,theta,rho) FROM stdin;\n";

my %keylist;

while(my $line = <FILE>) {
    chomp($line);

    my @data = split(",", $line);

    my $name         = $data[0];
    my $venue        = $data[1];
    my $date         = UnixDate(ParseDate($data[2]), '%Y-%m-%d');
    my $expiry       = UnixDate(ParseDate($data[5]), '%Y-%m-%d');
    my $strike       = $data[6];
    my $callput      = $data[7];
    my $ask          = $data[8]  ? $data[8]  : 0;
    my $bid          = $data[9]  ? $data[9]  : 0;
    my $price        = $data[10] ? $data[10] : 0;
    my $impliedvol   = $data[11] ? $data[11] : 0;
    my $volume       = $data[12] ? $data[12] : 0;
    my $openinterest = $data[13] ? $data[13] : 0;
    my $delta        = $data[16] ? $data[16] : 0;
    my $gamma        = $data[17] ? $data[17] : 0;
    my $vega         = $data[18] ? $data[18] : 0;
    my $theta        = $data[19] ? $data[19] : 0;
    my $rho          = $data[20] ? $data[20] : 0;

    $name =~ tr/[a-z]/[A-Z]/;
    $name =~ s/\'/\./g;

    if($venue eq 'TSE') {
        $name .= '.TO';
    } elsif($venue eq 'DE') {
        $name .= '.DE';
    }

    next if $name eq "PRS";

    $name = ($name eq "TUI1")  ? "TUI"  : $name;
    $name = ($name eq "QQQ")   ? "QQQQ" : $name;
    $name = ($name eq "SOXX")  ? "SOX"  : $name;

    my $key = join('_', $name, $date, $expiry, sprintf('%4.2f', $strike), $callput);

    if(exists $keylist{"$key"}) {
        print "Key exists: $key\n";
    } else {
        $keylist{"$key"} = 1;

        print OUTFILE join("\t", $name, $date, $expiry, $strike, $callput, $bid, $ask, $price, $impliedvol, $volume, $openinterest, $delta, $gamma, $vega, $theta, $rho) . "\n";
    }
}

print OUTFILE "\\.\n";

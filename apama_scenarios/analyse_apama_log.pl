#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Locale::Currency::Format;
use Getopt::Long;

my $exclude_list;
my $filename;
my $threshold = 0.0050;
my $showsymbolcount = 0;

GetOptions('filename=s'       => \$filename,
           'threshold=f'      => \$threshold,
           'exclude=s'        => \$exclude_list,
           'showsymbolcount!' => \$showsymbolcount);

my %exclude = map { $_ => 1 } split(",", $exclude_list);

### TODO [mcooney] Convert the script to a wrapper making function calls from a library


my @filtered_log;

$filename =~ /.*(\d{8}).*/;

my $datestr = $1;


### TODO [mcooney] Add granular control to the files produced by the script.

my $logfile       = "interlistedarb_filteredlog_$1.csv";
my $tradefile     = "interlistedarb_tradefile_$1.csv";
my $filterfile    = "interlistedarb_tradefile_filtered_$1.csv";
my $thresholdfile = "interlistedarb_threshold_$1.csv";

my %profit_hash;


open(FILE, "$filename") or die("Cannot open $filename for reading\n");

open(LOGFILE,       ">$logfile")          or die("Could not open $logfile for writing.\n");
open(TRADEFILE,     ">$tradefile")        or die("Could not open $tradefile for writing.\n");
open(FILTERFILE,    ">$filterfile")       or die("Could not open $filterfile for writing.\n");
open(THRESHOLDFILE, ">$thresholdfile")    or die("Could not open $thresholdfile for writing.\n");



while(my $line = <FILE>) {
    chomp($line);

    next if $line =~ /Correlator/;

    $line =~ s/INFO\] /INFO],/g;

    my ($timestamp, $symbol, $side, $CAsize, $CAprice, $USsize, $USprice, $FX, $profit) = split(",", $line);

    push(@filtered_log, $line) if (!$profit_hash{"$symbol"}{"$side"}{"$profit"});

    $profit_hash{"$symbol"}{"$side"}{"$profit"} = 1;
}

foreach my $line (@filtered_log) {
    print LOGFILE $line . "\n";
}



my %volume_count;

my $buy_count  = 0;
my $sell_count = 0;

my $total_spread = 0;
my $total_profit = 0;
my $total_shares = 0;

my $ts_sq = 0;
my $tp_sq = 0;

my $cad_total = 0;
my $usd_total = 0;

my $ca_factor = 0;
my $us_factor = 0;

print TRADEFILE     "symbol,tradesize,spread,profit,fx,cad,usd\n";
print FILTERFILE    "symbol,tradesize,spread,profit,fx,cad,usd\n";
print THRESHOLDFILE "symbol,tradesize,spread,profit,fx,cad,usd\n";

foreach my $line (@filtered_log) {
    my ($timestamp, $symbol, $side, $CAsize, $CAprice, $USsize, $USprice, $FX, $spread) = split(",", $line);

    if($side eq "BUY") {
        $buy_count++;

        $ca_factor = -1;
        $us_factor =  1;

    } else {
        $sell_count++;

        $ca_factor =  1;
        $us_factor = -1;
    }

    $USsize *= 100;

    my $tradesize = ($CAsize < $USsize) ? $CAsize : $USsize;

    my $ts = $spread;
    my $tp = ($tradesize * $spread);

    my $cad = $ca_factor * $tradesize * $CAprice;
    my $usd = $us_factor * $tradesize * $USprice;

    if(!$exclude{"$symbol"}) {
        $volume_count{"$symbol"} += $tradesize;

        $ts_sq += ($ts * $ts);
        $tp_sq += ($tp * $tp);

        $total_spread += $ts;
        $total_profit += $tp;

        $cad_total += $cad;
        $usd_total += $usd;
        
        $total_shares += $tradesize;
    }

    my $outputline = "$symbol,$tradesize,0$ts,$tp,$FX,$cad,$usd\n";
    
    print TRADEFILE $outputline;
    print FILTERFILE $outputline if !$exclude{"$symbol"};
    print THRESHOLDFILE $outputline if (!$exclude{"$symbol"} and ($spread > $threshold));
}

close(LOGFILE);
close(TRADEFILE);
close(THRESHOLDFILE);


my $tradecount = $buy_count + $sell_count;

print "Buys:\t${buy_count}\n";
print "Sells:\t${sell_count}\n";
print "Total:\t" . $tradecount . "\n";

print "\n";

print "Total CAD: " . currency_format('CAD', $cad_total) . "\n";
print "Total USD: " . currency_format('USD', $usd_total) . "\n";

print "\n";

my $average_profit = $total_profit / $tradecount;
my $stddev_profit  = sqrt(($tp_sq / $tradecount) - ($average_profit ** 2));

my $average_spread = $total_spread / $tradecount;
my $stddev_spread  = sqrt(($ts_sq / $tradecount) - ($average_spread ** 2));


print "Total trade profit:  \t" . currency_format('CAD', $total_profit) . "\n";
print "Total shares traded: \t" . sprintf("%10d",        $total_shares) . "\n";

print "Average trade profit:\t" . currency_format('CAD', $average_profit) . "\n";
print "Std dev trade profit:\t" . currency_format('CAD', $stddev_profit) . "\n";

print "Average trade spread:\t" . currency_format('CAD', $average_spread) . "\n";
print "Std dev trade spread:\t" . currency_format('CAD', $stddev_spread) . "\n";

print "\n";

if($showsymbolcount) {
    foreach my $symbol (sort {$volume_count{$a} <=> $volume_count{$b}} keys %volume_count) {
        print sprintf("%-10s\t%06d\n", $symbol, $volume_count{"$symbol"});
    }
}

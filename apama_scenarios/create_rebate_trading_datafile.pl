#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;

my %scenario_params;


my $symbols_file     = "rebatetrading_symbols.txt";
my $corrections_file = "rebatetrading_corrections.txt";
my $optdists_file    = "optimal_dists.txt";
my $timer_file       = "order_times.txt";
my $default_timer    = 30;

GetOptions('symbols_file=s'     => \$symbols_file,
           'optdists_file=s'    => \$optdists_file,
           'timer_file=s'       => \$timer_file,
           'default_timer=s'    => \$default_timer,
           'corrections_file=s' => \$corrections_file);

my %symbol_list      = ();
my %corrections_list = ();
my %timer_list       = ();

open(FILE, $symbols_file);

while(my $line = <FILE>) {
    chomp($line);
    $symbol_list{"$line"} = 1;
}

close(FILE);

if(-e $corrections_file) {
    open(FILE, $corrections_file);

    while(my $line = <FILE>) {
        chomp($line);
        
        my ($symbol, $value) = split(",", $line);
        
        $corrections_list{"$symbol"} = $value;
    }

    close(FILE);
}


open(FILE, $timer_file) or die("Cannot open timer file $timer_file");

while(my $line = <FILE>) {
    chomp($line);
    
    my ($symbol, $value) = split(",", $line);
    
    my $time = ($value ne "NA") ? $value : 0;
    
    $timer_list{"$symbol"} = sprintf("%4.2f", $time);
}

close(FILE);


open(FILE, $optdists_file);

foreach my $line (<FILE>) {
    chomp($line);

    my @data = split( ",", $line );

    my $symbol = $data[0];
    $symbol =~ s/\-(bid|ask)//g;

    my $bid_dist = 10000;
    my $ask_dist = 10000;

    if($symbol_list{"$symbol"}) {
        if(!$scenario_params{"$symbol"}) {
            $scenario_params{"$symbol"} = [];

            $scenario_params{"$symbol"}[0] = ($symbol =~ /\.TO/) ? "CA-Interlisted" : "US-Interlisted";
            $scenario_params{"$symbol"}[1] = $symbol;

            if($data[0] =~ /bid/) {
                $bid_dist = (abs($data[1]) < $bid_dist) ? abs($data[1]) : $bid_dist;
                $ask_dist = $bid_dist;
            }

            if($data[0] =~ /ask/) {
                $bid_dist = (abs($data[2]) < $bid_dist) ? abs($data[2]) : $bid_dist;
                $ask_dist = $bid_dist;
            }

            $scenario_params{"$symbol"}[4] = 100;        ## Order size
            $scenario_params{"$symbol"}[5] = 100000;     ## Max Volume
            $scenario_params{"$symbol"}[6] = "false";    ## Send Orders
            $scenario_params{"$symbol"}[7] = $timer_list{"$symbol"} ? $timer_list{"$symbol"} : $default_timer;

        } else {
            if($data[0] =~ /bid/) {
                $bid_dist = (abs($data[1]) < $bid_dist) ? abs($data[1]) : $bid_dist;
                $ask_dist = $bid_dist;
            }

            if($data[0] =~ /ask/) {
                $bid_dist = (abs($data[2]) < $bid_dist) ? abs($data[2]) : $bid_dist;
                $ask_dist = $bid_dist;
            }
        }
                
        $scenario_params{"$symbol"}[2] = sprintf("%4.2f", $bid_dist + $corrections_list{"$symbol"} );
        $scenario_params{"$symbol"}[3] = sprintf("%4.2f", $ask_dist + $corrections_list{"$symbol"} );
    }
}

close(FILE);


print "RebateTrading\n";

foreach my $symbol (sort keys %scenario_params) {
    print join( ",", @{ $scenario_params{"$symbol"} } ) . "\n";
}

exit(0);

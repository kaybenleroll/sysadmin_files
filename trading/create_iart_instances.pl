#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Locale::Currency::Format;
use Getopt::Long;

my $create_symbolset = 0;
my $notrade          = 0;

my $create_filename = "CreateDataRecorderInterlistedArbInstances.evt";
my $exchange_list   = "NYSE,AMEX,NASDAQ";
my $input_file      = "InterlistedStocks.csv";
my $us_symbolset    = "US-Interlisted";
my $ca_symbolset    = "CA-Interlisted";
my $currency_feed   = "Currenex";
my $username        = "mcooney";
my $buy_edge        = 0.01;
my $sell_edge       = 0.01;
my $order_size      = 100;
my $max_trades      = 1000;


GetOptions('create_symbolset!' => \$create_symbolset,
           'notrade!'          => \$notrade,
           'create_filename=s' => \$create_filename,
           'exchange_list=s'   => \$exchange_list,
           'ca_symbolset=s'    => \$ca_symbolset,
           'us_symbolset=s'    => \$us_symbolset,
           'currency_feed=s'   => \$currency_feed,
           'username=s'        => \$username,
           'input_file=s'      => \$input_file);

my %exchanges = map { $_ => 1 } split(",", $exchange_list);

open(INPUTFILE, "$input_file") or die("Cannot open $input_file for reading\n");

my @CA;
my @US;

while(my $line = <INPUTFILE>) {
    chomp($line);

    next if $line =~ /^$/;

    my @data = split(",", $line);

    next if $data[0] =~ /\.UN/;

    if($exchanges{$data[1]}) {
        push(@CA, $data[0] . ".TO");
        push(@US, $data[2] . ".");
    }
}

close(INPUTFILE);


### Configure the currency feed

my $currency_symbolset;
my $currency_symbol;

if($currency_feed eq "Currenex") {
    $currency_symbolset = "Currenex";
    $currency_symbol    = "USD/CAD";
    
} elsif($currency_feed eq "TSX") {
    $currency_symbolset = "FX-TSX";
    $currency_symbol    = "USDCAD.TO";
}

if($notrade) {
    $ca_symbolset .= "-NoTrade";
    $us_symbolset .= "-NoTrade";
    $currency_symbolset .= "-NoTrade";
}


open(CREATEFILE, ">$create_filename") or die("Cannot create file ${create_filename}");


for(my $i = 0; $i < @CA; $i++) {
    my $ca = $CA[$i];
    my $us = $US[$i];

    my $scenario_id = 7733457992001 + $i;

    print CREATEFILE "com.apama.scenario.Create(\"Scenario_InterlistedArbitrageRebateTrading\",${scenario_id},\"$username\",[\"${ca_symbolset}\",\"${us_symbolset}\",\"${currency_symbolset}\",\"$ca\",\"$us\",\"${currency_symbol}\",\"${buy_edge}\",\"${sell_edge}\",\"${order_size}\",\"${max_trades}\",\"true\")\n";
}

close(CREATEFILE);


if($create_symbolset) {
    my $symbolset_name = "CA-Interlisted";
    my $start_string = 'com.apama.ata.SymbolSet("' . ${symbolset_name} . '","ACTIV","ActivTransport","",{"resultType":"BBO"},"__ObjectionBasedFirewallControllerExternal","","","",{"Firewall.TargetService":"","1":"4PACCRF"},';

    print $start_string . '["' . join('","', @CA) . '"],[],{})' . "\n";
    
    $symbolset_name = "US-Interlisted";
    $start_string = 'com.apama.ata.SymbolSet("' . ${symbolset_name} . '","ACTIV","ActivTransport","",{"resultType":"BBO"},"__ObjectionBasedFirewallControllerExternal","","","",{"Firewall.TargetService":"","1":"4PACCRF"},';

    print $start_string . '["' . join('","', @US) . '"],[],{})' . "\n";
}
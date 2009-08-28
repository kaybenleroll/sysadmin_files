#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Locale::Currency::Format;
use Getopt::Long;

my $create_symbolset = 0;
my $notrade          = 0;

my $create_filename = "CreateRebateTradingInstances.evt";
my $exchange_list   = "NYSE,AMEX,NASDAQ";
my $input_file      = "RTStocks.csv";
my $us_symbolset    = "US-Interlisted";
my $ca_symbolset    = "CA-Interlisted";
my $username        = "mcooney";
my $start_id        = undef;

my $order_size      = 100;
my $max_volume      = 100000;
my $send_orders     = 0;

GetOptions('create_symbolset!' => \$create_symbolset,
           'notrade!'          => \$notrade,
           'send_orders!'      => \$send_orders,
           'create_filename=s' => \$create_filename,
           'exchange_list=s'   => \$exchange_list,
           'ca_symbolset=s'    => \$ca_symbolset,
           'us_symbolset=s'    => \$us_symbolset,
           'username=s'        => \$username,
           'start_id=s'        => \$start_id,
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
if($notrade) {
    $ca_symbolset .= "-NoTrade";
    $us_symbolset .= "-NoTrade";
}


open(CREATEFILE, ">$create_filename") or die("Cannot create file ${create_filename}");


my $scenario_id = $start_id ? $start_id : (1000000000000 + int(rand(100000000)) * 100000);

for(my $i = 0; $i < @CA; $i++) {
    my $ca = $CA[$i];

    $scenario_id++;

    my $send_orders_val = $send_orders ? "true" : "false";

    print CREATEFILE "com.apama.scenario.Create(\"Scenario_RebateTrading\",${scenario_id},\"$username\",[\"${ca_symbolset}\",\"$ca\",\"${order_size}\",\"${max_volume}\",\"${send_orders_val}\"])\n";
}

for(my $i = 0; $i < @US; $i++) {
    my $us = $US[$i];

    $scenario_id++;

    my $send_orders_val = $send_orders ? "true" : "false";

    print CREATEFILE "com.apama.scenario.Create(\"Scenario_RebateTrading\",${scenario_id},\"$username\",[\"${us_symbolset}\",\"$us\",\"${order_size}\",\"${max_volume}\",\"${send_orders_val}\"])\n";
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
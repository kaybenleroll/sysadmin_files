#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Locale::Currency::Format;
use Getopt::Long;

my $create_symbolset = 0;
my $notrade          = 0;

my $symbolset_name  = "DefaultSet";
my $input_filename  = "SymbolList.csv";
my $username        = "mcooney";


GetOptions('symbolset_name=s'  => \$symbolset_name,
           'input_filename=s'  => \$input_filename,
           'username=s'        => \$username);

my @data_list;
my @oms_list;

open(FILE, $input_filename) or die("Cannot open ${input_filename} for reading");


while(my $line = <FILE>) {
    chomp($line);
    
    my @data = split(",", $line);

    my $symbol = $data[0];
    my $type   = $data[2];

    my $data_suffix = ($type =~ /CDNX/) ? ".TV" : ".TO";

    push(@data_list, $symbol . $data_suffix);
    push(@oms_list, $symbol);
}

close(FILE);

print 'com.apama.ata.SymbolSet("' . $symbolset_name . '-NoTrade"' .
      ',"ACTIV","ActivTransport","",{"resultType":"BBO"},"__ObjectionBasedFirewallControllerExternal",' .
      '"","TSX_TRADING","",{"Firewall.TargetService":""},["' .
      join('","', @data_list) . '"],[],{})' . "\n";

print 'com.apama.ata.SymbolSet("SymbolSet-' . $symbolset_name . '"' .
      ',"ACTIV","ActivTransport","",{"resultType":"BBO"},"__ObjectionBasedFirewallControllerExternal",' .
      '"","TSX_TRADING","",{"Firewall.TargetService":""},["' .
      join('","', @data_list) . '"],["' . join('","', @oms_list) . '"],{})' . "\n";



exit(0);

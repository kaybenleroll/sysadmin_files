#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;

my $create_symbolset = 0;
my $notrade          = 0;

my $symbolset_name  = 'DefaultSet';
my $input_filename  = 'SymbolList.csv';
my $oms_market      = '__##NEED_OMS_MARKET##__';

GetOptions('symbolset_name=s'  => \$symbolset_name,
           'input_filename=s'  => \$input_filename,
           'oms_market=s'      => \$oms_market);

my @data_list;
my @oms_list;

open(FILE, $input_filename) or die("Cannot open ${input_filename} for reading");

my %suffix_hash = ('TSXV'   => '.TV',
                   'TSX'    => '.TO',
                   'US'     => '.',
                   'ARCA'   => '.EA',
                   'NYSE'   => '.N',
                   'NASDAQ' => '.Q',
                   'AMEX'   => '.A');


while(my $line = <FILE>) {
    chomp($line);

    my ($symbol, $venue) = split(",", $line);

    my $data_suffix = $suffix_hash{"$venue"} ? $suffix_hash{"$venue"} : "";

    push(@data_list, $symbol . $data_suffix);
    push(@oms_list, $symbol);
}

close(FILE);

print 'com.apama.ata.SymbolSet("' . $symbolset_name . '-NoTrade"' .
      ',"ACTIV","ActivTransport","",{"resultType":"BBO"},"__ObjectionBasedFirewallControllerExternal",' .
      '"","' . $oms_market . '","",{"Firewall.TargetService":""},["' .
      join('","', @data_list) . '"],[],{"SIMULATION_MODE":"OLDSTYLE"})' . "\n";

print 'com.apama.ata.SymbolSet("' . $symbolset_name . '"' .
      ',"ACTIV","ActivTransport","",{"resultType":"BBO"},"__ObjectionBasedFirewallControllerExternal",' .
      '"","' . $oms_market . '","",{"Firewall.TargetService":"FIX"},["' .
      join('","', @data_list) . '"],["' . join('","', @oms_list) . '"],{"SIMULATION_MODE":"OLDSTYLE"})' . "\n";


exit(0);

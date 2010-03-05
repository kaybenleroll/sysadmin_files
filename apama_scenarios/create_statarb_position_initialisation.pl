#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

while(my $line = <>) {
    next unless $line =~ / (.*) TRADEHALT (.*)/;

    my $scenario_label = $1;
    my ($driver_symbol, $quoter_symbol) = split('-', $scenario_label);

    my ($driver_pos, $driver_cash, $quoter_pos, $quoter_cash) = split(',', $2);

#    next unless (($driver_pos != 0) and ($quoter_pos != 0));

    my $message_key = "STATARB-POSITIONS-${scenario_label}";

    print "com.jacobsecurities.scenario.communication.DictionaryMessage(\"${message_key}\"," .
          "\{" .
          "\"${driver_symbol}-EXTPOS\":\"${driver_pos}\"," .
          "\"${driver_symbol}-EXTCASH\":\"${driver_cash}\"," .
          "\"${quoter_symbol}-EXTPOS\":\"${quoter_pos}\"," .
          "\"${quoter_symbol}-EXTCASH\":\"${quoter_cash}\"," .
          "\})\n";
}
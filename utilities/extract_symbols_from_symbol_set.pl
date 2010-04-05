#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;


while(my $line = <STDIN>) {
    next unless $line =~ /com\.apama\.ata\.SymbolSet.*\[(.*?)\],\[(.*?)\],\{.*\}/;

    my $md_symbols  = $1;
    my $oms_symbols = $2;

    print $md_symbols . "\n";
    my @symbols = split(",", $md_symbols);

    map { s/\"//g; print $_ . "\n" } @symbols;
}

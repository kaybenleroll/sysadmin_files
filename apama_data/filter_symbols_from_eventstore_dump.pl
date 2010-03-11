#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;

my $symbol_list = "ABX.TO,ABX.,RY.TO,RY.,G.TO,GG.,SU.TO,SU.,XIU.TO,S.,C.,CNQ.TO,CNQ.,RF.,USD/CAD";

GetOptions('symbol_list=s' => \$symbol_list);




print "# <Timezone=US/Eastern>\n";
print "#\n";

my @symbols = split(",", $symbol_list);

my $regexp = "(\"" . join("\"|\"", @symbols) . "\")";

while(my $line = <STDIN>) {
    next unless $line =~ /$regexp/;

    if(!($line =~ /SERVICE_NAME/ or $line =~ /USD\/CAD/)) {
        $line =~ s/\}/\"Exchange\":\"\",\"Market\":\"ActivTransport\",\"SERVICE_NAME\":\"ACTIV\"\}/g unless $line =~ /SERVICE_NAME/;
    }

    print $line;
}

exit(0);

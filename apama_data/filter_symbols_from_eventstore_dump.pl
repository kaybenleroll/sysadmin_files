#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;

my $symbol_list = "ABX.TO,ABX.,RY.TO,RY.,G.TO,GG.,SU.TO,SU.,XIU.TO,S.,C.,CNQ.TO,CNQ.,RF.,USD/CAD";

print "# <Timezone=US/Eastern>\n";
print "#\n";

my @symbols = split(",", $symbol_list);

my $regexp = "(\"" . join("\"|\"", @symbols) . "\")";

while(my $line = <>) {
    print $line if $line =~ /$regexp/;
}

exit(0);

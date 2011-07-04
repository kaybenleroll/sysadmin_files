#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Date::Manip;
use Getopt::Long;

use strict;

my %month_code = ('F' => 'Jan',
                  'G' => 'Feb',
                  'H' => 'Mar',
                  'J' => 'Apr',
                  'K' => 'May',
                  'M' => 'Jun',
                  'N' => 'Jul',
                  'Q' => 'Aug',
                  'U' => 'Sep',
                  'V' => 'Oct',
                  'X' => 'Nov',
                  'Z' => 'Dec');

my $exchange = '';

GetOptions('exchange=s'    => \$exchange);


while(my $line = <>) {
    chomp($line);

    my ($fullsymbol, $date, $open, $high, $low, $close, $volume, $openinterest) = split(",", $line);

    next if $line =~ '/^Symbol,/';

    if($fullsymbol =~ /(.+)([A-Z])(\d+)/) {
        my $symbol         = $1 . ".$exchange";
        my $delivery       = $2;
        my $year           = ($3 >= 90 ? 1900 : 2000) + $3;

        if(!exists($month_code{$delivery})) { print STDERR "\nUnknown Delivery month code " . $delivery . "," . $year . ",($fullsymbol),$line\n"; }

        my $delivery_month = $month_code{$2};
        my $lasttrade      = "1-" . $delivery_month . "-" . $year;

        print "$symbol,$date,$lasttrade,$open,$high,$low,$close,$volume,$openinterest\n";
    }
}

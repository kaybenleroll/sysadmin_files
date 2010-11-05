#!/usr/bin/perl -w

use LWP::UserAgent;
use Date::Manip;

use strict;

my $namefile = $ARGV[0];

open(FILE, $namefile);

my @symbols = <FILE>;
chomp(@symbols);

close(FILE);

my @start_dates = ( ParseRecur('first day of every month in 2009'), ParseRecur('first day of every month in 2010') );
my @end_dates   = ( ParseRecur('last day of every month in 2009'),  ParseRecur('last day of every month in 2010') );

print "Dates\n";
print join(' ', @start_dates) . "\n";
print join(' ', @end_dates) . "\n";


foreach my $symbol (@symbols) {
    for(my $index = 0; $index < @start_dates; $index++) {
        my $start_day   = UnixDate($start_dates[$index], '%d');
        my $start_month = UnixDate($start_dates[$index], '%m');
        my $start_year  = UnixDate($start_dates[$index], '%Y');

        my $end_day     = UnixDate($end_dates[$index], '%d');
        my $end_month   = UnixDate($end_dates[$index], '%m');
        my $end_year    = UnixDate($end_dates[$index], '%Y');

        my $url = "http://www.m-x.ca/nego_cotes_csv.php?symbol=${symbol}&lang_txt=en&jj=${start_day}&mm=${start_month}&aa=${start_year}&jjF=${end_day}&mmF=${end_month}&aaF=${end_year}";

        my $outputfile = "mxoptiondata_${symbol}_" . UnixDate($start_dates[$index], '%Y%m%d') . '_' . UnixDate($end_dates[$index] , '%Y%m%d') . '.csv';

        print $url . "\t" . $outputfile . "\n";

        my $response = LWP::UserAgent->new->request(HTTP::Request->new(GET => $url));

        unless($response->is_success()) {
            warn("URL: " . $response->status_line() . " not available\n");
        }

        open(FILE, ">" . $outputfile);
        print FILE $response->content();
        close(FILE);

        my $delay = int(rand(10) + 10);
        print("Waiting for " . $delay . " secs\n\n");
        sleep($delay);
    }
}


exit(0);

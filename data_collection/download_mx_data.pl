#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use LWP::UserAgent;
use Date::Manip;
use Getopt::Long;

use strict;

$|++;

my $namefile;
my $name       = 'XIU,ABX,SU,RY';
my $start_date;
my $end_date;
my $date;

GetOptions('namefile=s'    => \$namefile,
           'name=s'        => \$name,
           'date=s'        => \$date,
           'start_date=s'  => \$start_date,
           'end_date=s'    => \$end_date);

my @symbols;

if($namefile) {
    open(FILE, $namefile);

    ### Strip out the first line
    my $junk = <FILE>;

    @symbols = <FILE>;
    chomp(@symbols);

    close(FILE);
} elsif($name) {
    @symbols = split(",", $name);
} else {
    die("Need to supply either a name or namefile parameter\n");
}


my @start;
my @end;

if($date) {
    @start = split(",", $date);
    @end   = split(",", $date);
} else {
    @start = split(",", $start_date);
    @end   = split(",", $end_date);
}

if(@start != @end) {
    die("The start and end lists need to be of equal length\n");
}


foreach my $symbol (@symbols) {
    for(my $i = 0; $i < @start; $i++) {
        my $start_date = $start[$i];
        my $end_date   = $end[$i];

        my $start_day   = UnixDate($start_date, '%d');
        my $start_month = UnixDate($start_date, '%m');
        my $start_year  = UnixDate($start_date, '%Y');

        my $end_day     = UnixDate($end_date, '%d');
        my $end_month   = UnixDate($end_date, '%m');
        my $end_year    = UnixDate($end_date, '%Y');

        my $url = "http://www.m-x.ca/nego_cotes_csv.php?symbol=${symbol}&lang_txt=en&jj=${start_day}&mm=${start_month}&aa=${start_year}&jjF=${end_day}&mmF=${end_month}&aaF=${end_year}";

        my $outputfile;

        if(Date_Cmp($start_date, $end_date)) {
            $outputfile = "mxoptiondata_${symbol}_" . UnixDate($start_date, '%Y%m%d') . '_' . UnixDate($end_date , '%Y%m%d') . '.csv';
        } else {
            $outputfile = "mxoptiondata_${symbol}_" . UnixDate($start_date, '%Y%m%d') . '.csv';
        }

        print $url . "\t" . $outputfile . "\n";

        my $response = LWP::UserAgent->new->request(HTTP::Request->new(GET => $url));

        unless($response->is_success()) {
            warn("URL: " . $response->status_line() . " not available\n");
        }

        open(FILE, ">" . $outputfile);
        print FILE $response->content();
        close(FILE);

        my $delay = int(rand(3) + 1);
        print("Waiting for $delay secs\n\n");
        sleep($delay);
    }
}


exit(0);

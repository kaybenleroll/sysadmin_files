#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use LWP::UserAgent;
use Date::Manip;
use Getopt::Long;
use HTML::TableExtract;

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
} elsif($start_date) {
    @start = split(",", $start_date);
    @end   = split(",", $end_date);
} else {
    @start = UnixDate(ParseDate("yesterday"), '%Y-%m-%d');
    @end   = UnixDate(ParseDate("yesterday"), '%Y-%m-%d');
}

if(@start != @end) {
    die("The start and end lists need to be of equal length\n");
}


foreach my $symbol (@symbols) {
    for(my $i = 0; $i < @start; $i++) {
        my $start_date = $start[$i];
        my $end_date   = $end[$i];

	my $start_fetch = UnixDate($start_date, '%Y-%m-%d');
	my $end_fetch   = UnixDate($end_date,   '%Y-%m-%d');

        my $url = "http://www.m-x.ca/nego_cotes_xls.php?symbol=${symbol}&from=${start_fetch}&to=${end_fetch}";

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

	### Since the data is now returned in a Excel HTML format we need to change the data to CSV
	my $csv_data = "";

	my $te = HTML::TableExtract->new();
	$te->parse($response->content());

        if($response->is_success()) {
	    foreach my $t_row ($te->rows) {
		$csv_data .= join(';', @$t_row) . "\n";
	    }

	    open(FILE, ">" . $outputfile);
	    print FILE $csv_data;
	    close(FILE);
	}

	my $delay = int(rand(3) + 1);
	print("Waiting for $delay secs\n\n");
	sleep($delay);
    }
}


exit(0);

#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use Date::Manip;
use Spreadsheet::ParseExcel;

my $xls_file;

my $date;
my $symbol;
my $label;
my $long;
my $underlying;
my $value;

my %etf_data;

GetOptions('xls_file=s'       => \$xls_file );

my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse($xls_file);

if ( !defined $workbook ) {
    die $parser->error(), ".\n";
}

for my $worksheet ( $workbook->worksheets() ) {

    my ($row_min, $row_max) = $worksheet->row_range();

    ### Loop over each row
    for my $row ($row_min .. $row_max) {
        my $symbol_cell = $worksheet->get_cell($row, 1);

        ### If the row is blank or is a header for a dataset, skip it
        next unless $symbol_cell;
        next if $symbol_cell->unformatted() eq 'Trading Symbol';

        ### Note that the date cell uses the formatted value to avoid having to
        ### parse the Excel date format
        $date        = $worksheet->get_cell($row, 0)->value();
        $symbol      = $worksheet->get_cell($row, 1)->unformatted();
        $label       = $worksheet->get_cell($row, 2)->unformatted();
        $long        = $worksheet->get_cell($row, 3)->unformatted();
        $underlying  = $worksheet->get_cell($row, 4)->unformatted() ? $worksheet->get_cell($row, 4)->unformatted() : $underlying;
        $value       = $worksheet->get_cell($row, 7)->unformatted();

        next if $label =~ /(FUT|ZZZ|TNA)/;

        my $printdate = UnixDate(ParseDate($date), '%Y-%m-%d');

        ### Gather the data into a hash
        if($symbol) {
            $etf_data{"$underlying"}{"$symbol"}{"$label"} = $value;
            $etf_data{"$underlying"}{"$symbol"}{'DATE'}   = $printdate;
            $etf_data{"$underlying"}{"$symbol"}{'LONG'}   = ($long eq 'L') ? 1 : 0 if $long;
        }
    }
}

foreach my $underlying (keys %etf_data) {
    foreach my $symbol (keys %{ $etf_data{"$underlying"} }) {
        foreach my $label (keys %{ $etf_data{"$underlying"}{"$symbol"} }) {
            print "$underlying,$symbol,$label," . $etf_data{"$underlying"}{"$symbol"}{"$label"} . "\n";
        }

        print "\n";
    }

    print "--------------------\n";
    print "\n";
}

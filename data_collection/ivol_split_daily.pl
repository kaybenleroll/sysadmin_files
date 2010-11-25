#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use Date::Manip;

my $fh_read;
my $fh_write;

my $datafile;
my $output_stem;
my $replace_venue = 'DE';

GetOptions('datafile=s'      => \$datafile,
           'output_stem=s'   => \$output_stem,
           'replace_venue=s' => \$replace_venue);


if(!$datafile or !$output_stem) {
    die("Usage: $0 --datafile <datafile> --output_stem <output_stem>\n");
}


open($fh_read, $datafile) or die("Cannot read $datafile\n");

my $olddate  = "";
my $oldvenue = "";
my $newfile  = 0;


while(my $line = <$fh_read>) {
    my @data = split(",", $line);

    my $venue = $data[1];
    my $date  = $data[2];

    $venue = $replace_venue if $venue =~ /\//;

    if($olddate ne $date) {
        $olddate = $date;

        $newfile = 1;
    }

    if($oldvenue ne $venue) {
        $oldvenue = $venue;

        $newfile = 1;
    }


    if($newfile) {
        $newfile = 0;

        my $dateformat = UnixDate(ParseDate($date), '%Y%m%d');

        (my $filename = $output_stem) =~ s/XXXX/$dateformat/g;
        $filename =~ s/VENUE/$venue/g;

        close($fh_write) if $fh_write;
        open($fh_write, ">>" . $filename );
    }

    if($fh_write) {
        print $fh_write $line;
    } else {
        print "Handle closed: " . $line if !$fh_write;
    }
}

close($fh_write);

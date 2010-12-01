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
my $split_name    = 0;
my $split_venue   = 1;
my $split_date    = 1;

GetOptions('datafile=s'      => \$datafile,
           'output_stem=s'   => \$output_stem,
           'replace_venue=s' => \$replace_venue,
           'split_name!'     => \$split_name,
           'split_venue!'    => \$split_venue,
           'split_date!'     => \$split_date);


if(!$datafile or !$output_stem) {
    die("Usage: $0 --datafile <datafile> --output_stem <output_stem>\n");
}


open($fh_read, $datafile) or die("Cannot read $datafile\n");

my $oldlabel = "";


while(my $line = <$fh_read>) {
    next if $line =~ /^$/;

    my ($name, $venue, $datestr, @data) = split(",", $line);

    $venue = $replace_venue if $venue =~ /\//;

    my $date = UnixDate(ParseDate($datestr), '%Y%m%d');

    my @labelbuild = ();

    push(@labelbuild, $venue) if $split_venue;
    push(@labelbuild, $date)  if $split_date;
    push(@labelbuild, $name)  if $split_name;

    my $label = join("_", @labelbuild);

    if($label ne $oldlabel) {
        $oldlabel = $label;

        (my $filename = $output_stem) =~ s/XXXX/$label/g;

        close($fh_write) if $fh_write;
        open($fh_write, ">>" . $filename);
    }

    if($fh_write) {
        print $fh_write $line;
    } else {
        print "Handle closed: " . $line if !$fh_write;
    }
}

print "File: " . $datafile . " finished\n";

close($fh_write) if $fh_write;

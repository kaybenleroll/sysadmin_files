#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Date::Manip;

### Declaring variables and intializing default values
my $date = "today";
my $tstamp = undef;
my $filename = undef;
my %positions;
my $input;

### Get options to change the date of the file that is being created or to use a file as input
GetOptions('date=s'       => \$date,
           'filename=s'   => \$filename);

### Formats date and timestamp into proper formats
$date = UnixDate(ParseDate($date), "%Y/%m/%d");
$tstamp = UnixDate(ParseDate($date), "%m%d");

### If filename is entered use filename as input, otherwise use standard input
if ($filename) {
    $input = "RFILE";
    open(RFILE, $filename) || die ("Could not open file!");
} else {
    $input = "STDIN";
}

### Takes input and calculates the position for every symbol
while(my $line = <$input>) {
    my ($venue, $symbol, $side, $qty, $remain, $price) = split(",", $line);

    $positions{"$venue"}{"$symbol"}{"$side"}{"count"}    += 1;
    $positions{"$venue"}{"$symbol"}{"$side"}{"quantity"} += $qty;
    $positions{"$venue"}{"$symbol"}{"$side"}{"money"}    += $qty * $price;
}

close(RFILE);

### Go through for each venue
foreach my $venue (sort keys %positions) {

    my $total_currency = 0;
    my $count = 0;

    ### skip if venue is CNX
    next if $venue eq "CNX";

    ### if venue is US open us file, if ca open ca file
    if($venue eq "US"){ 
        open (FILE, ">F96TR${tstamp}2.csv");
    } elsif ($venue eq "CA"){
        open (FILE, ">F96TR${tstamp}1.csv")
    }

    ### Print out the header and titles for the file
    print FILE "00000HDR\n";
    print FILE "#,A/C,Nam,RR,MKT,QTY,Price,B/S,TB,Symbol,Security,Cusip,TD,SD,Comm,F/X,CT,A01,A02,A03,A04,O/C,CXL,75,77,HM,INV/GB,BACCT,BRR,BT/B,BCOMM,BF/X,BCT,B75,B77,BINV/GB,BHM\n";

    ### Go through for each symbol and side, calculate the average price, and assign the fills and shares values to their variables
    foreach my $symbol (sort keys %{ $positions{"$venue"} }) {
        foreach my $side (sort keys %{ $positions{"$venue"}{"$symbol"} }) {
            my $fills     = $positions{"$venue"}{"$symbol"}{"$side"}{"count"};
            my $shares    = $positions{"$venue"}{"$symbol"}{"$side"}{"quantity"};
            my $avg_price = sprintf("%0.6f", $positions{"$venue"}{"$symbol"}{"$side"}{"money"} / $shares);

            #Switch side from word to letter format
            if($side eq "BUY") {
                $side = "B";
            } elsif ($side eq "SELL") {
                $side = "S";
            } else {
                $side = "ERROR";
            }

            #Print out data to file in proper format and count the number of times data is ouput
            $count += 1;
            
            if($venue eq "US"){
                print FILE "$count,2SDAAYF,,,XY,$shares,$avg_price,$side,P,$symbol,,,$date,,,,,,,,,N,,,,,,4PEC83D,4PAA,T,0,,,,,,,,N,\n";
            } elsif ($venue eq "CA"){
                print FILE "$count,2SDAAYE,,,T,$shares,$avg_price,$side,P,$symbol,,,$date,,,,,,,,,,,,,,,,,,,,,,,,\n";    
            }

             
            next if $venue =~ /CNX/;
        }
    }

    ### convert count into a 5digit lengthed number and print out the footer of the file
    my $number = sprintf ("%05d", $count);

    print FILE "00000TLR$number\n";
    print FILE "//\n";
 

    close(FILE);
}

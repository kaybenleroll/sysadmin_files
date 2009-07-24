#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Date::Manip;

my $date = "today";
my $tstamp = undef;
my $filename = undef;

GetOptions('date=s'       => \$date,
           'filename=s'   => \$filename);

$date = UnixDate(ParseDate($date), "%Y/%m/%d");
$tstamp = UnixDate(ParseDate($date), "%m%d");

my %positions;
my $input;

if ($filename){
    $input = "RFILE";
    open(RFILE, $filename) || die ("Could not open file!");

}else{
    $input = "STDIN";

}

while(my $line = <$input>) {
    my ($venue, $symbol, $side, $qty, $remain, $price) = split(",", $line);

    $positions{"$venue"}{"$symbol"}{"$side"}{"count"}    += 1;
    $positions{"$venue"}{"$symbol"}{"$side"}{"quantity"} += $qty;
    $positions{"$venue"}{"$symbol"}{"$side"}{"money"}    += $qty * $price;
}
close(RFILE);

foreach my $venue (sort keys %positions) {

    my $total_currency = 0;
    my $count = 0;
    next if $venue eq "CNX";
    if($venue eq "US"){ 
        open (FILE, ">F96TR${tstamp}2.csv");
    } elsif ($venue eq "CA"){
        open (FILE, ">F96TR${tstamp}1.csv")
    }

    print FILE "00000HDR\n";
    print FILE "#,A/C,Nam,RR,MKT,QTY,Price,B/S,TB,Symbol,Security,Cusip,TD,SD,Comm,F/X,CT,A01,A02,A03,A04,O/C,CXL,75,77,HM,INV/GB,BACCT,BRR,BT/B,BCOMM,BF/X,BCT,B75,B77,BINV/GB,BHM\n";

    foreach my $symbol (sort keys %{ $positions{"$venue"} }) {
	foreach my $side (sort keys %{ $positions{"$venue"}{"$symbol"} }) {
	    my $fills     = $positions{"$venue"}{"$symbol"}{"$side"}{"count"};
	    my $shares    = $positions{"$venue"}{"$symbol"}{"$side"}{"quantity"};
	    my $avg_price = sprintf("%0.6f", $positions{"$venue"}{"$symbol"}{"$side"}{"money"} / $shares);
	    
	    #print "$venue,$symbol,$side,$shares,$avg_price\n";



	    if($side eq "BUY"){
		$side = "B";
	    } elsif ($side eq "SELL"){
		$side = "S";
	    }else {
		$side = "ERROR";
	    }

	    $count += 1;
	    if($venue eq "US"){    
		print FILE "$count,4PABCRF,,,XY,$shares,$avg_price,$side,P,$symbol,,,$date,,,,,,,,,N,,,,,,4PEC83D,4PAA,T,0,,,,,,,,N,\n";
    	    } elsif ($venue eq "CA"){
		print FILE "$count,4PABCRE,,,T,$shares,$avg_price,$side,P,$symbol,,,$date,,,,,,,,,,,,,,,,,,,,,,,,\n";	
  	    }

             
	    next if $venue =~ /CNX/;

	    #$total_currency += $positions{"$venue"}{"$symbol"}{"$side"}{"money"} * ($side eq "BUY" ? -1 : 1);
	}
    }

    my $number = sprintf ("%05d", $count);
    print FILE "00000TLR$number\n";
    print FILE "//\n";
 

    close(FILE);
    #print "\n$venue,${total_currency}\n\n" unless $venue =~ /CNX/;
}


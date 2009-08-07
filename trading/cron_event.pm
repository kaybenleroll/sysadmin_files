#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use File::Copy;
use Net::FTP;
use Date::Manip;

sub main {

    my $date     = 'today';
    my $tstamp   = undef;
    my $host     = '207.35.239.17';
    my $user     = 'F96FTP01';
    my $pass     = 'VLZWR3IBK1';

    my $filename;

    GetOptions('filename=s'   => \$filename,
               'date=s'       => \$date,
               'host=s'       => \$host,
               'user=s'       => \$user,
               'password=s'   => \$pass);

    $date        = UnixDate(ParseDate($date), "%Y%m%d");
    $tstamp      = UnixDate(ParseDate($date), "%m%d");

    $filename = "/var/jsi/atalogs/ATA_correlator_${date}*";

    open(RFILE, $filename) || die ("Could not open file!");

    system("cat $filename | grep OrderUpdate | perl process_fills.pl > trades_${date}.csv");

    system("cat $filename | grep OrderUpdate | perl process_fills.pl | grep -v HTC | perl calculate_pnl.pl > pnl_${date}.csv");

    system("cat trades_*  |  grep -v HTC | perl calculate_pnl.pl > cumlpnl_${date}.csv");

    system("cat $filename | grep OrderUpdate | perl process_fills.pl | perl generate_dropfile.pl");

    move("F96TR${tstamp}1.csv", "/var/jsi/pensonfiles/");
    move("F96TR${tstamp}2.csv", "/var/jsi/pensonfiles/");

    system("cat /var/jsi/torcfiles/JacobSecurities_${date} | perl rollup_torc.pl | perl generate_dropfile.pl");

    system("diff F96TR${tstamp}2 /var/jsi/pensonfiles/F96TR${tstamp}2");

    system("rm F96TR${tstamp}2");

    #my $ftp_h = Net::FTP->new($host, Debug => 0);
    #$ftp_h->login($user, $pass);
    #$ftp_h->cwd("/eod");
    #$ftp_h->put("F96TR${tstamp}1.csv");
    #$ftp_h->put("F96TR${tstamp}2.csv");

}

sub process_fills {
    my $l;

    my %positions;
    while(my $line = <>) {
        if ($line =~ /.*OrderUpdate\((.*)\)/){


        my @data = split(",", $1);
        my %hash;

        my $orderid   = $data[0];
        my $symbol    = $data[1];
        my $side      = $data[3];
        my $executed  = $data[14];
        my $remaining = $data[15];
        my $price     = $data[18];
        my $status    = $data[19];


        next unless $orderid =~ /^"[^_]/;
        next unless $status  =~ /Filled:/;

        $symbol =~ s/"//g;
        $side   =~ s/"//g;

        my $venue;

        if($line =~ /TSX_TRADING/) {
	    $venue = "CA";
        } elsif($line =~ /TORC_TRADING/) {
	    $venue = "US";
        } elsif($line =~ /CURRENEX_TRADING/) {
	    $venue = "CNX";
        } else {
	    print "Error parsing entry $line";
        }

        my $printprice;

        if($venue eq "CNX") {
	    $printprice = sprintf("%8.6f", $price);
        } else {
	    $printprice = sprintf("%4.2f", $price);
        }


        $hash{$orderid} = "$venue,$symbol,$side,$executed,$remaining,$printprice";
        print "$hash{$orderid}\n";

    
        $positions{"$venue"}{"$symbol"}{"$side"}{"count"} += 1;
        $positions{"$venue"}{"$symbol"}{"$side"}{"quantity"} += $executed;
        $positions{"$venue"}{"$symbol"}{"$side"}{"money"} += $executed * $price;
        }
    }

    exit(0);

    print "\n\nSummary:\n\n";
}

sub calculate_pnl {
    
    my $cad_cashflow = 0;
    my $usd_cashflow = 0;
    my $ca_volume = 0;
    my $us_volume = 0;
    my $ca_cashvolume = 0;
    my $us_cashvolume = 0;
    my $unhedged_pnl = 0;
    my $exchange_rate = 0;

    my $cad_fx = 0;
    my $usd_fx = 0;

    my %ca_positions;
    my %us_positions;

    while(my $line = <>) {
        my ($venue, $symbol, $side, $qty, $remain, $price) = split(",", $line);

        if($venue eq "CNX") {
	    $usd_fx                  += ($qty          * ($side eq "BUY" ?  1 : -1));
	    $cad_fx                  += ($qty * $price * ($side eq "BUY" ? -1 :  1));
            $exchange_rate            = ($price        +(($side eq "BUY" ? -1 :  1)*0.00025));
        } elsif($venue eq "CA") {
	    $ca_positions{"$symbol"} += ($qty          * ($side eq "BUY" ?  1 : -1));
	    $cad_cashflow            += ($qty * $price * ($side eq "BUY" ? -1 :  1));
	    $ca_volume               += ($qty         );
	    $ca_cashvolume           += ($qty * $price);
        } elsif($venue eq "US") {
	    $us_positions{"$symbol"} += ($qty          * ($side eq "BUY" ?  1 : -1));
	    $usd_cashflow            += ($qty * $price * ($side eq "BUY" ? -1 :  1));
	    $us_volume               += ($qty         );
	    $us_cashvolume           += ($qty * $price); 
        } else {
	    print "Error with line $line";
        }
    }


    foreach my $symbol (sort keys %ca_positions) {
        print $symbol . "," . $ca_positions{"$symbol"} . "\n"; 
    }

    print "\n";

    foreach my $symbol (sort keys %us_positions) {
        print $symbol . "," . $us_positions{"$symbol"} . "\n"; 
    }

    $unhedged_pnl = $usd_cashflow * $exchange_rate + $cad_cashflow;

    print "\n\n";
    print "CAD Cashflow: " . sprintf("% 10.2f", $cad_cashflow) . "\n";
    print "CAD FX:       " . sprintf("% 10.2f", $cad_fx) . "\n";
    print "CAD Total:    " . sprintf("% 10.2f", $cad_fx + $cad_cashflow) . "\n";
    print "\n";
    print "USD Cashflow: " . sprintf("% 10.2f", $usd_cashflow) . "\n";
    print "USD FX:       " . sprintf("% 10.2f", $usd_fx) . "\n";
    print "USD Total:    " . sprintf("% 10.2f", $usd_fx + $usd_cashflow) . "\n";
    print "\n";
    print "CA Cash Volume: " . sprintf("% 10.2f", $ca_cashvolume) . "\n";
    print "CA Volume       " . sprintf("% 10.2f", $ca_volume) . "\n";
    print "US Cash Volume: " . sprintf("% 10.2f", $us_cashvolume) . "\n";
    print "US Volume       " . sprintf("% 10.2f", $us_volume) . "\n";
    print "\n";
    print "Unhedged PNL: " . sprintf("%10.2f", $unhedged_pnl) . "\n";


}

sub generate_dropfile {
    
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
        if ($venue eq "US"){ 
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
}

sub generate_tradefile {
    
    my $today;
    my $date;
    my $tstamp;
    my $err;
    my $some_dir = "/var/jsi/atalogs/";
    my @array;
    my $count = 0;

    $today  = UnixDate(ParseDate('today'), "%Y%m%d");
    $today  = DateCalc($today,"+ 1 days",\$err);
    $today  = UnixDate(ParseDate($today), "%Y%m%d");
    $date   = UnixDate(ParseDate('May 8th, 2009'), "%Y%m%d");
    $tstamp = UnixDate(ParseDate($date), "%m%d");


    while ($date != $today){

        if (-e "/var/jsi/apama/logfiles/apamalogs_${date}.tar.bz2") {
            chdir "/var/jsi/tradefile_pnl";
            system("cat /var/jsi/atalogs/*correlator_${date}* | grep OrderUpdate | perl /var/jsi/tradefile_pnl/process_fills.pl > trades_${date}.csv");   
            system("cat /var/jsi/tradefile_pnl/trades_${date}.csv | grep -v HTC | perl /var/jsi/tradefile_pnl/calculate_pnl.pl > pnl_${date}.csv");
            $array[$count] = "/var/jsi/atalogs/*correlator_${date}* ";
            $count = $count + 1;
            system("cat @array | grep OrderUpdate | perl process_fills.pl | perl calculate_pnl.pl > cumlpnl_${date}.csv");
        }

        $date   = DateCalc($date,"+ 1 days",\$err);
        $date   = UnixDate(ParseDate($date), "%Y%m%d");
        $tstamp = UnixDate(ParseDate($date), "%m%d");

    }
}

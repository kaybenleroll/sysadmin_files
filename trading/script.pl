#!/usr/bin/perl -w

use strict;
use warnings;

use Text::CSV;
use Getopt::Long;
use Date::Manip;
use DBI;

my $count = 0;
my $count2 = 0;
my $avg;
my $Symbol;
my $bids;
my $asks;
my $bidquantities;
my $askquantities;
my $time;
my $BidSize;
my $Bid;
my $AskSize;
my $Ask;
my $number;
my $filename;
my @data;

my $tradePrice;
my $tradeQuantity;
my $cumulativevalue;
my $cumulativevolume;
my $TradeCount;
my $TradeDate;
my $TradeCondition;
my $TradeTime;
my $CumulativePrice;
my $LastReportedTradeSize;
my $LastReportedTradeTime;
my $TradeExchange;  

my $date = "today";
my $tstamp = undef;

$date = UnixDate(ParseDate($date), "%Y/%m/%d");
$tstamp = UnixDate(ParseDate($date), "%y%m%d");

GetOptions('date=s'       => \$date,
           'filename=s'   => \$filename);

$filename = "dump_${tstamp}";
open(FILE, ">$filename.sim");
print FILE "#\n# <Timezone=US/Eastern>\n#\n";

while(my $line = <>) {
    
    if ($count == 75000){
        $count = 0;
        close(FILE);
        $count2 = $count2 + 1;
        $number = sprintf ("%03d", $count2);
        $filename = "dump_${tstamp}_${number}";
        open(FILE, ">$filename.sim");    
        print FILE "#\n# <Timezone=US/Eastern>\n#\n";        
    }

    if ($line =~ /.*ActivMarketBBODepth\((.*)\)/){

        @data = split(",",$1);

        if ($#data >= 12){
      
            $Symbol         = $data[0];
	    $bids           = $data[1];
            #$bids           =~ s/[//g;
            #$bids           =~ s/]//g;
	    $asks           = $data[2];
            #$asks           =~ s/[//g;
            #$asks           =~ s/]//g;
            #$avg            = ($bids + $asks)/2;
	    $bidquantities  = $data[3];
	    $askquantities  = $data[4];
            $time           = $data[6];
            $time           =~ /(\d{10}.\d)(\d{5})/;
            $time           = $1;
            $BidSize        = $data[10];
            #$BidSize        =~ s/{//g;
            $Bid            = $data[11];
            $AskSize        = $data[12];
            $Ask            = $data[13];
            #$Ask            =~ s/})//g;

            $count          = $count + 1;
            
            print FILE "${time}00,internal,com.apama.marketdata.Depth($Symbol,$bids,$asks,[NUMBER],$bidquantities,$askquantities,{$Ask,$AskSize,$Bid,$BidSize,\"requestType\":\"-8\"})\n";
            }
        
        else{

            $Symbol         = $data[0];
	    $bids           = $data[1];
            #$bids           =~ s/[//g;
            #$bids           =~ s/]//g;
	    $asks           = $data[2];
            #$asks           =~ s/[//g;
            #$asks           =~ s/]//g;
            #$avg            = ($bids + $asks)/2;
	    $bidquantities  = $data[3];
	    $askquantities  = $data[4];
            $time           = $data[6];
            $time           =~ /(\d{10}.\d)(\d{5})/;
            $time                  = $1;
            $AskSize        = $data[9];
            $Ask            = $data[11];
            #$Ask            =~ s/})//g;

            $count          = $count + 1;

            print FILE "${time}00,internal,com.apama.marketdata.Depth($Symbol,$bids,$asks,[NUMBER],$bidquantities,$askquantities,{$Ask,$AskSize,\"requestType\":\"-8\"})\n";
        }
    }
    elsif ($line =~ /.*ActivMarketTick\((.*)\)/){

        @data = split(",",$1);
             
    	$Symbol                = $data[0];
	$tradePrice            = $data[1];
	$tradeQuantity         = $data[2];
        $time                  = $data[4];        
        $time                  =~ /(\d{10}.\d)(\d{5})/;
        $time                  = $1;
        $cumulativevalue       = $data[7];
        #$cumulativevalue       =~ s/{//g;        
        $cumulativevolume      = $data[8];
        $TradeCount            = $data[9];
        $TradeDate             = $data[10];
        $TradeCondition        = $data[11];
        $TradeTime             = $data[12];
        $CumulativePrice       = $data[13];
        $LastReportedTradeSize = $data[14];
        $LastReportedTradeTime = $data[15];
        $TradeExchange         = $data[16];        

        $count                 = $count + 1;

        print FILE "${time}00,internal,com.apama.marketdata.Tick($Symbol,$tradePrice,$tradeQuantity,{$CumulativePrice,$cumulativevalue,$cumulativevolume,$LastReportedTradeSize,$LastReportedTradeTime,$TradeCondition,$TradeCount,$TradeDate,$TradeExchange,$TradeTime,\"requestType\":\"-7\"})\n";

    }

}

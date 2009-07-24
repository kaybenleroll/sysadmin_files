#!/usr/bin/perl -w

use strict;
use warnings;

use Text::CSV;
use Getopt::Long;
use DBI;

while($line = <>) {
    
    if ($line =~ /.*ActivHeartbeatRequest\((.*)\)/){
    	string $requestId;
	dictionary<integer,float> timeStamp;
        @data = split(",",$1);
      
        $requestId              = $data[0];        

        print FILE "";
   
    }

    elsif ($line =~ /.*ActivHeartbeatResponse\((.*)\)/){
    	string $requestId;
	integer $HeartbeatStatus;
	dictionary<integer,float> timeStamp;
        @data = split(",",$1);
      
        $requestId              = $data[0];
        $HeartbeatStatus        = $data[1];

   
    }

    elsif ($line =~ /.*ActivConnectRequest\((.*)\)/){
    	string $logonRequestId;
	string $activServiceId;
	string $userLogin;
	string $password;
	dictionary<integer,float> timeStamp;
        @data = split(",",$1);
      
        $symbol              = $data[0];        
    	$logonRequestId      = $data[1];
	$activServiceId      = $data[2];
	$userLogin           = $data[3];
	$password            = $data[4];

   
    }

    elsif ($line =~ /.*ActivConnectReply\((.*)\)/){
    	string $logonRequestId;
	string $activServiceId;
	string $userLogin;
	string $SessionToken;
	integer $statusCode;
	string $statusMsg;
	dictionary<integer,float> timeStamp;
	dictionary<string,string> __payload;
        
        @data = split(",",$1);
      
        $symbol             = $data[0];        
    	$logonRequestId     = $data[1];
	$activServiceId     = $data[2];
	$userLogin          = $data[3];
	$SessionToken       = $data[4];
	$statusCode         = $data[5];
	$statusMsg          = $data[6];

   
    }

    elsif ($line =~ /.*ActivSubscribeRequest\((.*)\)/){
    	string $subscribeRequestId;
	string $subscribeType;
	string $SessionToken;
	string $Symbol;
	boolean $isBBO10;
	dictionary<integer,float> timeStamp;
        @data = split(",",$1);
      
        $symbol              = $data[0];        
    	$subscribeRequestId  = $data[1];
	$subscribeType       = $data[2];
	$SessionToken        = $data[3];
	$Symbol              = $data[4];
	$isBBO10             = $data[5];

   
    }

    elsif ($line =~ /.*ActivSubscribeResponse\((.*)\)/){
    	string $subscribeRequestId;
	string $subscribeType;
	string $SessionToken;
	string $Symbol;
	string $status;
	string $statusMsg;
	dictionary<integer,float> timeStamp;
	dictionary<string,string> __payload;
        @data = split(",",$1);
      
    	$subscribeRequestId   = $data[0];
	$subscribeType        = $data[1];
	$SessionToken         = $data[2];
	$Symbol               = $data[3];
	$status               = $data[4];
	$statusMsg            = $data[5];        

   
    }

    elsif ($line =~ /.*ActivUnsubscribeRequest\((.*)\)/){
    	string $unsubscribeRequestId;
	string $unsubscribeType;
	string $SessionToken;
	string $Symbol;
	boolean $isBBO10;
	dictionary<integer,float> timeStamp;
        @data = split(",",$1);
      
        $unsubscribeRequestId = $data[0];
	$unsubscribeType      = $data[1];
	$SessionToken         = $data[2];
	$Symbol               = $data[3];
	$isBBO10              = $data[4];

   
    }

    elsif ($line =~ /.*ActivUnsubscribeResponse\((.*)\)/){
    	string $unsubscribeRequestId;
	string $unsubscribeType;
	string $SessionToken;
	string $Symbol;
	string $status;
	string $statusMsg;
	dictionary<integer,float> timeStamp;
	dictionary<string,string> __payload;
        @data = split(",",$1);
                  
    	$unsubscribeRequestId = $data[0];
	$unsubscribeType      = $data[1];
	$SessionToken         = $data[2];
	$Symbol               = $data[3];
	$status               = $data[4];
	$statusMsg            = $data[5];

   
    }

    elsif ($line =~ /.*ActivMarketDepth\((.*)\)/){
    	string $Symbol;
	sequence < float > $bids;
	sequence < float > $asks;
	sequence < integer > $bidquantities;
	sequence < integer > $askquantities;
	dictionary<integer,float> timeStamp;
	dictionary<string,string> __payload;
        @data = split(",",$1);
            
    	$Symbol         = $data[0];
	$bids           = $data[1];
	$asks           = $data[2];
	$bidquantities  = $data[3];
	$askquantities  = $data[4];

   
    }

    elsif ($line =~ /.*ActivMarketBBODepth\((.*)\)/){
    	string $Symbol;
	sequence < float > $bids;
	sequence < float > $asks;
	sequence < integer > $bidquantities;
	sequence < integer > $askquantities;
	dictionary<integer,float> timeStamp;
	dictionary<string,string> __payload;
        @data = split(",",$1);
      
    	$Symbol         = $data[0];
	$bids           = $data[1];
	$asks           = $data[2];
	$bidquantities  = $data[3];
	$askquantities  = $data[4];        

        print FILE "${time}00,internal,com.apama.marketdata.Depth("$Symbol",$bids,$asks,[33.585],$bidquantities,$askquantities,{"Ask":"33.59","AskSize":"6","Bid":"33.58","BidSize":"16","requestType":"-8"})";
   
    }

    elsif ($line =~ /.*ActivMarketTick\((.*)\)/){
    	string $Symbol;
	float $tradePrice;
	integer $tradeQuantity;
	dictionary<integer,float> timeStamp;
	dictionary<string,string> __payload;
        @data = split(",",$1);
      
       
    	$Symbol          = $data[0];
	$tradePrice      = $data[1];
	$tradeQuantity   = $data[2];
        
        $symbol =~ s/"//g;
        $side   =~ s/"//g;

   
    }

    elsif ($line =~ /.*ActivDisconnectRequest\((.*)\)/){
    	string $logoffRequestId;
	string $activServiceId;
	string $userLogin;
	string $SessionToken;
	dictionary<integer,float> timeStamp;
        @data = split(",",$1);
              
    	$logoffRequestId = $data[0];
	$activServiceId  = $data[1];
	$userLogin       = $data[2];
	$SessionToken    = $data[3];

        $symbol =~ s/"//g;
        $side   =~ s/"//g;

   
    }

    elsif ($line =~ /.*ActivDisconnectReply\((.*)\)/){
    	string $logoffRequestId;
	string $activServiceId;
	string $userLogin;
	string $SessionToken;
	integer $statusCode;
	dictionary<integer,float> timeStamp;
	dictionary<string,string> __payload;
        @data = split(",",$1);
              
    	string $logoffRequestId = $data[0];
	string $activServiceId  = $data[1];
	string $userLogin       = $data[2];
	string $SessionToken    = $data[3];
	integer $statusCode     = $data[4];

        $symbol =~ s/"//g;
        $side   =~ s/"//g;

   
    }

    elsif ($line =~ /.*ActivContentGatewayConnectionDown\((.*)\)/){
    	string $activServiceId;
	string $userLogin;
	sequence < string > $SessionTokens;
	dictionary<integer,float> timeStamp;
	dictionary<string,string> __payload;
        @data = split(",",$1);
             
    	$activServiceId  = $data[0];
	$userLogin       = $data[1];
	$SessionTokens   = $data[2];
        
        $symbol =~ s/"//g;
        $side   =~ s/"//g;

   
    }
}

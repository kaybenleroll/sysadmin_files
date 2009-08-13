#!/usr/bin/perl -w

use strict;
use warnings;

use Text::CSV;
use Getopt::Long;
use DBI;

#Declaration of variables
my $sqlstatement = undef;
my $count = undef;
my $orderid = undef;
my $symbol = undef;
my $price = undef;
my $side = undef;
my $type = undef;
my $quantity = undef;
my $inMarket = undef;
my $isVisible = undef;
my $modifiable = undef;
my $cancelled = undef;
my $orderChangeRejected = undef;
my $externallyModified = undef;
my $unknownState = undef;
my $marketOrderId = undef;
my $executed = undef;
my $remaining = undef;
my $lastShares = undef;
my $lastPrice = undef;
my $avgPrice = undef;
my $status = undef;
my $serviceId = undef;
my $brokerId = undef;
my $bookId = undef;
my $marketId = undef;
my $exchange = undef;
my $ownerId = undef;
my $line = undef;
my $timestamp = undef;
my $symbolcode = undef;
my $expectedprofit = undef;
my $tradecode = undef;
my $csv;
my @data;
my @data1;
my $dictionary;
my $sql;
my $sth;
my $database = 'tradesdb';
my $host = 'localhost';
my $port = '5432';
my $dbuser = 'volare';
my $dbpass = 'vol0410jaj';

#Get options for host, database name, port, username and password for the database
GetOptions('host=s'       => \$host,
	   'database=s'   => \$database,
	   'port=s'       => \$port,
           'user=s'       => \$dbuser,
           'password=s'   => \$dbpass);

#Connects to the database using host, database name, port, username and password
my $dbh = DBI->connect ( "dbi:Pg:dbname=$database;host=$host;port=$port", "$dbuser", "$dbpass") or die "$DBI::errstr\n";


while($line = <>) {

    #Pulls the timestamp out of the line using regular expressions    
    $line =~ /^(.*?) CRIT/;
    $timestamp = $1;

    #Filters the OrderUpdate lines out and stores the information in the data array   
    if ($line =~ /.*OrderUpdate\((.*)\)/){
    
        @data = split(",",$1);

        #Pulls the dictionary out of the line using regular expressions
        $line =~ /.*\{(.*)\}/;
        $dictionary = $1;

        #Assigns data to their respective variables
        $orderid             = $data[0];
        $symbol              = $data[1];
        $price               = $data[2];
        $side                = $data[3];
        $type                = $data[4];
        $quantity            = $data[5];
        $inMarket            = $data[6];
        $isVisible           = $data[7];
        $modifiable          = $data[8];
        $cancelled           = $data[9];
        $orderChangeRejected = $data[10];
        $externallyModified  = $data[11];
        $unknownState        = $data[12];
        $marketOrderId       = $data[13];
        $executed            = $data[14];
        $remaining           = $data[15];
        $lastShares          = $data[16];
        $lastPrice           = $data[17];
        $avgPrice            = $data[18];
        $status              = $data[19];

        #Checks to make sure orderid and status are valid and if not skips line
        next unless $orderid =~ /^"[^_]/;
        next unless $status  =~ /\"Filled:/;

        #Removes quotations from symbol and side
        $symbol =~ s/"//g;
        $side   =~ s/"//g;

        #Setting the sql statement
        $sql = "INSERT INTO OrderUpdate (orderid, timestamp, symbol, price, side, type, quantity, inMarket, isVisible, modifiable, cancelled, orderChangeRejected, externallyModified, unknownState, marketOrderId, qtyexecuted, qtyremaining, lastShares, lastPrice, avgPrice, status, dictionary) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"; 

        # Prepares the sql statement and checks to make sure it prepared correctly
        $sth = $dbh->prepare($sql);    
        if ( !defined $sth ) {
            die "Cannot prepare statement: $DBI::errstr\n";
        } 
        
        #Executes the sql statement which uploads all the data to their respective columns
        my $rv = $sth->execute($orderid,$timestamp,$symbol,$price,$side,$type,$quantity,$inMarket,$isVisible,$modifiable,$cancelled,$orderChangeRejected,$externallyModified,$unknownState,$marketOrderId,$executed,$remaining,$lastShares,$lastPrice,$avgPrice,$status,$dictionary);
    }

    #Filters out the NewOrder lines and stores their information in the data array
    if ($line =~ /.*NewOrder\((.*)\)/){

        #Continues to perform the same actions as above for the New order data 
        @data = split(",", $1);

        $line =~ /.*\{(.*)\}/;
        $dictionary = $1;

        $orderid             = $data[0];
        $symbol              = $data[1];
        $price               = $data[2];
        $side                = $data[3];
        $type                = $data[4];
        $quantity            = $data[5];
        $serviceId           = $data[6];
        $brokerId            = $data[7];
        $bookId              = $data[8];
        $marketId            = $data[9];
        $exchange            = $data[10];
        $ownerId             = $data[11];
    
        next unless $orderid =~ /^"[^_]/;
        #next unless $status =~ /\"Filled:/;

        $symbol =~ s/"//g;
        $side   =~ s/"//g;

        $sql = "INSERT INTO Orders (orderid,timestamp,symbol,price,side,type,quantity,serviceId,brokerId,bookId,marketId,exchange,ownerId,dictionary) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

        $sth = $dbh->prepare($sql);     
        if ( !defined $sth ) {
            die "Cannot prepare statement: $DBI::errstr\n";
        }
 
        my $rv1 = $sth->execute($orderid,$timestamp,$symbol,$price,$side,$type,$quantity,$serviceId,$brokerId,$bookId,$marketId,$exchange,$ownerId,$dictionary);


        $orderid =~ /:([A-Z]{1,5}(\.|\.TO)):/;
        $symbolcode = $1;

        if (!$symbolcode){
            $symbolcode = $symbol;
        }
        
        $orderid =~ /$symbolcode\:(.*)\:/;
        $tradecode = $1;

        if (!$tradecode){
            $tradecode = $orderid;
        }

        $sql = "INSERT INTO Trade (symbolcode,timestamp,expectedprofit,tradecode) VALUES (?,?,?,?)";

        $sth = $dbh->prepare($sql);     
        if ( !defined $sth ) {
            die "Cannot prepare statement: $DBI::errstr\n";
        }
 
        my $rv2 = $sth->execute($symbolcode,$timestamp,$expectedprofit,$tradecode);
    }

}




#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use DBI;

my %positions;
my $sqlstatement;
my $count;
my $orderid;
my $symbol;
my $price;
my $side;
my $type;
my $quantity;
my $inMarket;
my $isVisible;
my $modifiable;
my $cancelled;
my $orderChangeRejected;
my $externallyModified;
my $unknownState;
my $marketOrderId;
my $executed;
my $remaining;
my $lastShares;
my $lastPrice;
my $avgPrice;
my $status;
my $serviceId;
my $brokerId;
my $bookId;
my $marketId;
my $exchange;
my $ownerId;
my $line;
my @data;
my @dictionary;
my $sql;
my $sth;
my $database = 'trades';
my $host = 'localhost';
my $port = '5432';
my $dbuser = 'tradeuser';
my $dbpass = 'trade';

GetOptions('host=s'       => \$host);

my $dbh = DBI->connect ( "dbi:Pg:dbname=$database;host=$host;port=$port", "$dbuser", "$dbpass") or die "$DBI::errstr\n";

while($line = <>) {
    $line =~ /.*OrderUpdate\((.*)\)/;

    @data = split(",", $1);

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

    $count = 20;
    while ($data[$count]){
        @dictionary      = $data[$count];
        $count = $count + 1;
    }

    next unless $orderid =~ /^"[^_]/;
    next unless $status  =~ /\"Filled:/;

    $symbol =~ s/"//g;
    $side   =~ s/"//g;
    
    $sql = "INSERT INTO OrderUpdate (orderid, symbol, price, side, type, quantity, inMarket, isVisible, modifiable, cancelled, orderChangeRejected, externallyModified, unknownState, marketOrderId, executed, remaining, lastShares, lastPrice, avgPrice, status, dictionary) VALUES ($orderid,$symbol,$price,$side,$type,$quantity,$inMarket,$isVisible,$modifiable,$cancelled,$orderChangeRejected,$externallyModified,$unknownState,$marketOrderId,$executed,$remaining,$lastShares,$lastPrice,$avgPrice,$status,@dictionary)";
    $sth = $dbh->prepare($sql);
    if ( !defined $sth ) {
        die "Cannot prepare statement: $DBI::errstr\n";
    } 
    $sth->execute;

}



while($line = <>) {
    $line =~ /.*NewOrder\((.*)\)/;


    @data = split(",", $1);

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
    
    $count = 12;
    while ($data[$count]){
        @dictionary         = $data[$count];
        $count = $count + 1;
    }

    next unless $orderid =~ /^"[^_]/;
    next unless $status  =~ /\"Filled:/;

    $symbol =~ s/"//g;
    $side   =~ s/"//g;

    $sql = "INSERT INTO NewOrder (orderid,symbol,price,side,type,quantity,serviceId,brokerId,bookId,marketId,exchange,ownerId,dictionary) VALUES ($orderid,$symbol,$price,$side,$type,$quantity,$serviceId,$brokerId,$bookId,$marketId,$exchange,$ownerId,@dictionary)";
    $sth = $dbh->prepare($sql);     
    if ( !defined $sth ) {
        die "Cannot prepare statement: $DBI::errstr\n";
    } 
    $sth->execute;

}



use strict;
use warnings;
use Date::Manip;
use Getopt::Long;

### Declaration of variables
my $start_date = '20090508';
my $code_dir = '/home/russell/sysadmin/trade_reporting/extract_trades_from_fix_log.pl';
my $end_date = 'today';
my $file_dir = '~/trades';
my $err;

GetOptions('start_date=s'   => \$start_date,
           'end_date=s'     => \$end_date,
	   'code_dir=s'     => \$code_dir,
	   'file_dir=s'     => \$file_dir);

my $datemanip = ParseDate($start_date);
$start_date = UnixDate($datemanip, "%Y%m%d");
$datemanip = ParseDate($end_date);
$end_date = UnixDate($datemanip, "%Y%m%d");
my $flag  = Date_Cmp($start_date,$end_date);

while ($start_date ne $end_date){
    if(-d "/var/jsi/storage/fixlogs/$start_date/"){
	system("cat /var/jsi/storage/fixlogs/$start_date/FIX_Log/*.messages.log | perl $code_dir > $file_dir/trades_$start_date.csv");
    }
		$start_date = DateCalc($start_date,'+ 1 business days',\$err);
	$datemanip  = ParseDate($start_date);
        $start_date = UnixDate($datemanip, "%Y%m%d");
	$flag       = Date_Cmp($start_date,$end_date);

}

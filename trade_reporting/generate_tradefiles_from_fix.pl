use strict;
use warnings;
use Date::Manip;
use Getopt::Long;

### Declaration of variables
my $start_date = '20090508';
my $code_dir   = '/home/russell/sysadmin/trade_reporting';
my $end_date   = 'today';
my $file_dir   = '/var/jsi/storage/';
my $dailypnl   = 1;
my $cumlpnl    = 1;
my $trades     = 1;
my $count      = 0;
my @filearray;
my $err;

GetOptions('start_date=s'   => \$start_date,
           'end_date=s'     => \$end_date,
           'code_dir=s'     => \$code_dir,
           'file_dir=s'     => \$file_dir,
           'dailypnl!'     => \$dailypnl,
           'cumlpnl!'      => \$cumlpnl,
           'trades!'       => \$trades);

$start_date = UnixDate(ParseDate($start_date), "%Y%m%d");
$end_date = UnixDate(ParseDate($end_date), "%Y%m%d");

while ($start_date ne $end_date) {
    if(-d "${file_dir}/fixlogs/${start_date}/" and $trades) {
        system("cat ${file_dir}/fixlogs/${start_date}/FIX_Log/*.messages.log | perl ${code_dir}/extract_trades_from_fix_log.pl > ${file_dir}/trades/trades_${start_date}.csv");
    }
    
    if(-e "${file_dir}/trades/trades_${start_date}.csv" and $dailypnl) {
        system("cat ${file_dir}/trades/trades_${start_date}.csv | perl ${code_dir}/extract_pnl_from_tradefiles.pl > ${file_dir}/dailypnl/dailypnl_${start_date}.csv");
    }
    
    if(-e "${file_dir}/trades/trades_${start_date}.csv" and $cumlpnl) {
	    $filearray[$count] = "${file_dir}/trades/trades_${start_date}.csv";
        $count++;
        system("cat @filearray | perl ${code_dir}/extract_pnl_from_tradefiles.pl > ${file_dir}/cumlpnl/cumlpnl_${start_date}.csv");
    }

    $start_date = DateCalc($start_date,'+ 1 business days',\$err);
    $start_date = UnixDate(ParseDate($start_date), "%Y%m%d");

}

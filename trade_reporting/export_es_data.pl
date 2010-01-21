#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use Date::Manip;

my $date = 'today';

my $es_db_dir  = '/apama/apama-work/eventstore/db/Default';
my $output_dir = '/apama/filestorage/eventstore_dumps';

GetOptions('date=s'       => \$date,
           'es_db_dir=s'  => \$es_db_dir,
           'output_dir=s' => \$output_dir);

my $file_date  = UnixDate(ParseDate($date), "%Y%m%d");
my $input_date = UnixDate(ParseDate($date), "%Y.%m.%d");


my $cmd_string = "esutil -d ${es_db_dir} -dir ${output_dir} --name BaseFileName --value dump_${file_date} --startTime ${input_date}:09:20:00 --endTime ${input_date}:16:30:00";
print "$cmd_string\n";

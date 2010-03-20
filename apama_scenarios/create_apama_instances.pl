#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Getopt::Long;

my $create_symbolset = 0;
my $notrade          = 0;

my $username          = "mcooney";
my $create_filename   = undef;
my $input_file        = undef;
my $start_instance_id = undef;
my $header_file       = undef;

GetOptions('create_filename=s' => \$create_filename,
           'header_file=s'     => \$header_file,
           'username=s'        => \$username,
           'start_id=s'        => \$start_instance_id,
           'input_file=s'      => \$input_file);

open(INPUTFILE, "$input_file") or die("Cannot open $input_file for reading\n");

my $scenario_name = <INPUTFILE>;
chomp($scenario_name);

open(CREATEFILE, ">$create_filename") or die("Cannot create file ${create_filename}");

my $scenario_id = $start_instance_id ? $start_instance_id : (1000000000000 + int(rand(100000000)) * 100000);

if($header_file) {
    open(FILE, $header_file) or die("Unable to open $header_file for reading\n");
    
    my @text = <FILE>;
    
    print CREATEFILE join("", @text) . "\n\n";
}

while(my $line = <INPUTFILE>) {
    chomp($line);
    
    $scenario_id++;
    
    my @input_data = map { "\"$_\"" } split(",", $line);
    
    my $input_params = join(",", @input_data);
    
    print CREATEFILE "com.apama.scenario.Create(\"Scenario_${scenario_name}\",${scenario_id},\"$username\",[${input_params}])\n";    
}


close(CREATEFILE);

#!/usr/local/bin/perl
use strict;

my @process_list = qw(strong nom weak nnsp nnwp snnp wnnp snwp wnsp weak_eol snwp_eol);
my @vdds_list    = qw(1.35 1.5 1.62 1.65 1.8 1.98);
my @temp_list    = qw(-40 25 125);
my @res_list     = qw(50);

open(FILE,">./code_comparison.xls.csv") || die "Failed to open code_comparison.xls.csv in write mode\n";
print FILE "process,temp,vdds,res,true_p,true_n,pseudo_p,pseudo_n\n";

foreach my $res (@res_list){
	foreach my $process (@process_list){
		foreach my $temp (@temp_list){
			foreach my $vdds (@vdds_list){

chomp(my $pst=(split('=',`/bin/grep pslices= ${process}_${temp}_${vdds}_${res}.truecode`  ))[1]);
chomp(my $nst=(split('=',`/bin/grep nslices= ${process}_${temp}_${vdds}_${res}.truecode`  ))[1]);
chomp(my $psp=(split('=',`/bin/grep pslices= ${process}_${temp}_${vdds}_${res}.pseudocode`))[1]);
chomp(my $nsp=(split('=',`/bin/grep nslices= ${process}_${temp}_${vdds}_${res}.pseudocode`))[1]);

print FILE "$process,$temp,$vdds,$res,$pst,$nst,$psp,$nsp,\n";
			}
		}
	}
}

close(FILE);

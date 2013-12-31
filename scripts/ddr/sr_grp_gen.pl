#!/usr/local/bin/perl
use strict;

my $numslices=59;
my @grouping=(7,5,3);

my $slice=1;
my $strp="";
my $strn="";

my $upperbound;
my $lowerbound;

foreach my $i (@grouping){
	
	print "$slice  ";
	$strp="pcpre_,".$strp;
	$strn="ncpre_,".$strn;
	
	$upperbound=$slice+$i-1;
	$lowerbound=$slice;
	
	$strp="pcpre_dly<$upperbound:$lowerbound>,".$strp;
	$strn="ncpre_dly<$upperbound:$lowerbound>,".$strn;
	printf("%d:%d  ",$lowerbound+1,$upperbound+1);
	$slice+=$i+1;
		
}	

while($slice<$numslices){

	print "$slice  ";
	$strp="pcpre_,".$strp;
	$strn="ncpre_,".$strn;
	
	$upperbound=$slice+$grouping[-1]-1;
	$lowerbound=$slice;
	
	$strp="pcpre_dly<$upperbound:$lowerbound>,".$strp;
	$strn="ncpre_dly<$upperbound:$lowerbound>,".$strn;
	printf("%d:%d  ",$lowerbound+1,$upperbound+1);
	$slice+=$grouping[-1]+1;

}

$strp =~ s/,$//;
$strn =~ s/,$//;
print "\n$strp\n$strn\n";

exit 0; 

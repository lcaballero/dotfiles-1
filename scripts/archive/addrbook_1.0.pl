#!/tools/local/perl
use strict; 

#my $a='"Shetty,"	Malini	"Shetty, Malini"		malinishetty@ti.com		';
#my $b='		"Prashanth, B"		b-prashanth@ti.com					';
#my $c='Sumantha	Madhyastha	"Madhyastha, Sumantha"		sumantham@ti.com';

my $field;

open(IN, "<contacts.txt");
open(OUT, ">newcontacts.txt");
while(<IN>){
	chomp();
	next if(/^First Name/);
	if(/^(\w+)\s+(\w+).*\s+(\w+@\w+(\.\w+)+)/){
	#Case 1: To match First and Last name and to generate the Display name
		$field="$1\t$2\t\"$2, $1\"\t\t$3\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\n";
	#	print "Matched without quotes\n";
	}elsif(/.*\"(.+), (.+)\s*\"\s+(.+@\w+(\.\w+)+)/){		
	#Case 2: To match the Display Name and generate the First and Last names
		$field="$2\t$1\t\"$2, $1\"\t\t$3\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\n";
	#	print "Matched quotes\n";
	}else{
	#Case 3: Fallback case in case nothing matches
		$field=${_}."\n";
		print "Matched nothing for $field";
	}
	print OUT $field;
}

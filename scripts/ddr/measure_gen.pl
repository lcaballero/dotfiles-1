#!/usr/local/bin/perl
#
# Script to generate measure statements for nbit and next_nand_p in DDR IO Slice

use strict;

open(FILEP,">measure_statements");

print FILEP "* Measure statements for DDR slices\n";
#print FILEP ".MEA OP P0 MAX V(XP.PCODE_0)\n";
#print FILEP ".MEA OP N0 MAX V(XP.NCODE_0)\n";
print FILEP "*\n";
#for (my $i=1; $i<7; $i++){
#	print FILEP ".MEA OP PCODE${i} MAX V(XP.PCODE_${i})\n";
#	print FILEP ".MEA OP NCODE${i} MAX V(XN.NCODE_${i})\n";
#	print FILEP ".MEA OP PCODE_${i} MAX V(XP.PCODE__${i})\n";
#	print FILEP ".MEA OP NCODE_${i} MAX V(XN.NCODE__${i})\n";
#	print FILEP "*\n";
#}
for (my $i=59; $i>0; $i--){
	print FILEP ".MEA TR PCPRE_${i} MAX V(X0.XIBIT_${i}.pcpre_)\n";
	print FILEP ".MEA TR NCPRE_${i} MAX V(X0.XIBIT_${i}.ncpre_)\n";

}

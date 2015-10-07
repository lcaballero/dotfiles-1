#!/usr/local/bin/perl

use strict;
use diagnostics;

# Convert a decimal to a binary
sub dec2bin {
	my $str = unpack("B32", pack("N", shift));
#	$str =~ s/^0+(?=\d)//;   # To remove leading zeros
#	Using 6 bits (including leading 0s)
	my @long=split(//,$str);
	my @short=@long[26..31];
	my $shortstr=join('',@short);
}

# Convert a binary number to a decimal number
sub bin2dec {
	unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

# XOR Function
sub myxor {
	return 0 if ($_[0]==$_[1]);
	return 1 if ($_[0]!=$_[1]);
}

# Binary to Gray-Code Converter
sub bin2gray {
	my @bin=split(//,$_[0]);
	
	my @gray;
	$gray[0]=$bin[0];
	for(my $i=1; $i<=$#bin ; $i++){		
		$gray[$i]=myxor($bin[$i],$bin[$i-1]);
	}

	my $graystr=join('',@gray);
}

# Decimal to Gray-Code Converter
sub dec2gray {
	bin2gray(dec2bin($_[0]));
}

# Gray-code Adder
sub myaddgray {
	my @g1=split(//,$_[0]);
	my @g2=split(//,$_[1]);
	
	my $logic="";
	$logic = ($g1[0]==0 ?        "pcode_<6> " :        "pcode<6> ") if ($g1[0]==$g2[0]);
	$logic = ($g1[1]==0 ? $logic."pcode_<5> " : $logic."pcode<5> ") if ($g1[1]==$g2[1]);
	$logic = ($g1[2]==0 ? $logic."pcode_<4> " : $logic."pcode<4> ") if ($g1[2]==$g2[2]);
	$logic = ($g1[3]==0 ? $logic."pcode_<3> " : $logic."pcode<3> ") if ($g1[3]==$g2[3]);
	$logic = ($g1[4]==0 ? $logic."pcode_<2> " : $logic."pcode<2> ") if ($g1[4]==$g2[4]);
	$logic = ($g1[5]==0 ? $logic."pcode_<1> " : $logic."pcode<1> ") if ($g1[5]==$g2[5]);

	$logic;
}

# Slice logic generator
sub myslicelogic {
	my $n0=$_[0];
	my $n1=$_[0]+1;
	myaddgray(dec2gray($n0),dec2gray($n1));
}

my $code;
my @slicecode;
my $s1="";
my $s2="";
my $s3="";
my $s4="";
my $s5="";

for (my $i=1; $i<50; $i++){
	my $code=myslicelogic($i);
	@slicecode = split(/ /,$code);
	$s1="$slicecode[4],$s1";
	$s2="$slicecode[3],$s2";
	$s3="$slicecode[2],$s3";
	$s4="$slicecode[1],$s4";
	$s5="$slicecode[0],$s5";
}

$s1 =~ s/^,//;
$s2 =~ s/^,//;
$s3 =~ s/^,//;
$s4 =~ s/^,//;
$s5 =~ s/^,//;

print "$s1\n\n";
print "$s2\n\n";
print "$s3\n\n";
print "$s4\n\n";
print "$s5\n";

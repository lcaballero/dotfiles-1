#!/usr/local/bin/perl 
#
# Script to generate the PVT codes for PMOS and NMOS (PCODE, NCODE)
# This is done by measuring the resistances of PMOS and NMOS final driver transistors in DDR IO Slice
# and dividing it by the training resistance to get the number of slices required at that PVT condition
# to ensure that the output impedence is the same as the training impedence

use strict;



#===========
# Variables 
#===========
my $netlist = "/proj/gateway4/products/gs70/expts/a0393831/SIMULATIONS/ddr/netlists/bcshtltcscdvpbfz_slice.spi";
my $always_on = 10;		# No. of always on slices
my $bits = 5;			# No. of bits

my @m= qw(strong nom weak nnsp nnwp snnp wnnp snwp wnsp weak_eol snwp_eol);
my @t= qw(-40 25 125);
my @v= qw(1.35 1.5 1.62 1.65 1.8 1.98);
my @trainres= qw(50);

my %vmap = (
    '0' => "PVSS",
	'1' => "PVDD"
);



foreach my $process (@m){
	foreach my $temp (@t){
		foreach my $vdds (@v){
	
my $deckp="./pcode_${process}_${temp}_${vdds}.deck";
my $deckn="./ncode_${process}_${temp}_${vdds}.deck";


#=============================================================
# Create a deck to calculate the single-slice PMOS resistance
#=============================================================
open(DECKP,">$deckp");
print DECKP 
"** Setup to measure the single-slice resistance of the PMOS 
**
*** SPICE OPTIONS ***
.INC /proj/gateway/products/gs70/spice_models/spice_options


*** MODELS ***
.INC /proj/gateway/products/gs70/spice_models/archive/2009.01.30_lvdrain/models_${process} NOPRINT


*** Slice NETLIST ***
.INC ${netlist} NOPRINT


*** PARAMETERS ***
.PARAM pvdds = $vdds
.PARAM pvss = 0
.PARAM pvdd = 1
.TEMP $temp


*** COMPONENTS ***
VDDS VDDS 0 pvdds
VDD  VDD  0 pvdd
VSS  VSS  0 0
VSSS VSSS 0 0
VIN  IN   0 pvdd

VPAD PAD 0 DC 0

** VDDS VSS PAD PCPRE VDD SR1ANDSR0_ NEXT_NAND_N PREV_NAND_P PREV_NAND_N TERMP_ SR1ORSR0_ TERMN SR0 NEXT_NAND_P PCPRE_DLYIN PCPRE_DLY NCPRE_DLY NCPRE_DLYIN NCPRE HHV  SR0_ SR1ORSR0 HHV_ NCODEIN_5 NCODEIN_4 NCODEIN_3 NCODEIN_2 NCODEIN_1 PCODEIN_5 PCODEIN_4 PCODEIN_3 PCODEIN_2 PCODEIN_1 VSSS VBBNW SR1ANDSR0 bcshtltcscdvpbfz_slice
XP VDDS VSS PAD IN    VDD VDD        NEXT_NAND_N VSS         VSS         VDD    VDD       VSS   VSS NEXT_NAND_P VSS         PCPRE_DLY NCPRE_DLY VSS         IN    VSSS VDD  VSS      VDDS VSS       VSS       VSS       VSS       VSS       VSS       VSS       VSS       VSS       VSS       VSSS VDD   VSS       bcshtltcscdvpbfz_slice


*** ANALYSIS ***
.DC VPAD 0 pvdds 0.01

.PU DC 'abs(I(Vpad))'
.MEA DC IP_VDDSBY2 FIND I(VPAD) AT='PVDDS*0.5'
.MEA DC IMP_P PARAM 'ABS((PVDDS*0.5)/IP_VDDSBY2)'


.END
";
close(DECKP);

# Simulate and check to see if the simulation was completed successfully
if(system("/apps/ame/bin/spice3 $deckp ")==1){
	print "\nSpice simulation to calculate resistance of PMOS failed\n";
	exit(1);
}


#=============================================================
# Create a deck to calculate the single-slice NMOS resistance
#=============================================================
open(DECKN,">$deckn");
print DECKN
"** Setup to measure the single-slice resistance of the NMOS
**
*** SPICE OPTIONS ***
.INC /proj/gateway/products/gs70/spice_models/spice_options


*** MODELS ***
.INC /proj/gateway/products/gs70/spice_models/archive/2009.01.30_lvdrain/models_${process} NOPRINT


*** Slice NETLIST ***
.INC ${netlist} NOPRINT


*** PARAMETERS ***
.PARAM pvdds = $vdds
.PARAM pvss = 0
.PARAM pvdd = 1
.TEMP $temp


*** COMPONENTS ***
VDDS VDDS 0 pvdds
VDD  VDD  0 pvdd
VSS  VSS  0 0
VSSS VSSS 0 0
VIN  IN   0 pvss

VPAD PAD 0 DC 0

** VDDS VSS PAD PCPRE VDD SR1ANDSR0_ NEXT_NAND_N PREV_NAND_P PREV_NAND_N TERMP_ SR1ORSR0_ TERMN SR0 NEXT_NAND_P PCPRE_DLYIN PCPRE_DLY NCPRE_DLY NCPRE_DLYIN NCPRE HHV  SR0_ SR1ORSR0 HHV_ NCODEIN_5 NCODEIN_4 NCODEIN_3 NCODEIN_2 NCODEIN_1 PCODEIN_5 PCODEIN_4 PCODEIN_3 PCODEIN_2 PCODEIN_1 VSSS VBBNW SR1ANDSR0 bcshtltcscdvpbfz_slice
XN VDDS VSS PAD IN    VDD VDD        NEXT_NAND_N VSS         VSS         VDD    VDD       VSS   VSS NEXT_NAND_P VSS         PCPRE_DLY NCPRE_DLY VSS         IN    VSSS VDD  VSS      VDDS VSS       VSS       VSS       VSS       VSS       VSS       VSS       VSS       VSS       VSS       VSSS VDD   VSS       bcshtltcscdvpbfz_slice


*** ANALYSIS ***
.DC VPAD 0 pvdds 0.01

.PU DC 'abs(I(vpad))'
.MEA DC IN_VDDSBY2 FIND I(VPAD) AT='PVDDS*0.5'
.MEA DC IMP_N PARAM 'ABS((PVDDS*0.5)/IN_VDDSBY2)'


.END
";
close(DECKN);

# Simulate and check to see if the simulation was completed successfully
if(system("/apps/ame/bin/spice3 $deckn ")==1){
	print "\nSpice simulation to calculate resistance of NMOS failed \n";
	exit(1);
}


# Extract the single-slice impedences from the .prt files
my ($pimp)=(`/bin/grep -i ^IMP_P ${deckp}.prt` =~ /(\S+$)/);
my ($nimp)=(`/bin/grep -i ^IMP_N ${deckn}.prt` =~ /(\S+$)/);


#========================================================
# Generate Code Files for different training resistances
#========================================================
foreach my $res (@trainres){
my $deck="./${process}_${temp}_${vdds}_${res}.truecode";

print "Processing for PTV: $process, $temp, $vdds, $res\n";

# Total number of slices required to maintain the output resistance at training resistance value
my $pslice=$pimp/$res;
my $nslice=$nimp/$res;
# Number of variable slices...
my $pcode_dec=int($pslice) + ($pslice-int($pslice)>=0.001?1:0) - $always_on;
my $ncode_dec=int($nslice) + ($nslice-int($nslice)>=0.001?1:0) - $always_on;

# Convert decimal codes to binary and reversal can be done to align the Voltage MSB with last element of list (Not done here)
my @pcode=split(//,sprintf("%0${bits}b",$pcode_dec));
my @ncode=split(//,sprintf("%0${bits}b",$ncode_dec));

# Output binary codes as voltage sources
open(DECK,">$deck");
print DECK
"*Codes: [P: @pcode] [N: @ncode] Pslices(ON):$pcode_dec Nslices(ON):$ncode_dec

.PARAM pslices=$pcode_dec
.PARAM nslices=$ncode_dec

VP5 P5 0 $vmap{$pcode[0]}
VP4 P4 0 $vmap{$pcode[1]}
VP3 P3 0 $vmap{$pcode[2]}
VP2 P2 0 $vmap{$pcode[3]}
VP1 P1 0 $vmap{$pcode[4]}

VN5 N5 0 $vmap{$ncode[0]}
VN4 N4 0 $vmap{$ncode[1]}
VN3 N3 0 $vmap{$ncode[2]}
VN2 N2 0 $vmap{$ncode[3]}
VN1 N1 0 $vmap{$ncode[4]}
";
close(DECK);
			}
		}
	}
}

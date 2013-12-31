#!/usr/bin/perl -w
use strict;

my @process_list = qw(strong nom weak nnsp nnwp snnp wnnp snwp wnsp weak_eol snwp_eol);
my @vdds_list    = qw(1.35 1.5 1.62 1.65 1.8 1.98);
my @temp_list    = qw(-40 25 125);
my @res_list     = qw(50);

my $model_path = "/proj/gateway/products/gs70/spice_models/archive/2009.08.10.inline";
my $netlists_path = "/proj/gateway4/products/gs70/expts/a0393831/SIMULATIONS/bcshtltcscdvpbfz/netlists";

my $vdd = 1;
my $limcycle = 50;
my $totalslices = 41;
my $alwayson = 10;
my $bits=5;
my $vdd=1;

my %vmap = (
    '0' => "pvss",
	'1' => "pvdd"
);

my $i=0;
foreach my $res (@res_list){
	foreach my $process (@process_list){
		foreach my $temp (@temp_list){
			foreach my $vdds (@vdds_list){

my $pslices=10;
my $nslices=10;
my $pout=0;
my $nout=0;

my $deck="truecode_${process}_${temp}_${vdds}_${res}.deck";
print "Processing for $process, $temp, $vdds, $res ...\n";


for (my $cycle=1 ; $cycle < $limcycle ; $cycle++){
open(DECK,">./$deck") || die "Failed to open $deck in write mode\n";

print DECK "
** Setup to find p/n truecodes by emulating VTP Macro blocks
**
*** OPTIONS ***
.OPTIONS NOLIST NOMOD NONODE NOOPTS NOOP NOSCALE_ERROR 
+ TOL=1E-7 TRATOL=1E-10 LVLSUB=0 GMIN=1E-15 DISPFREQ=0


*** NETLISTS ***
.INC $netlists_path/codegen_pslice.spi NOPRINT 
.INC $netlists_path/codegen_nslice.spi NOPRINT 
.INC $netlists_path/codegen_comparator.spi NOPRINT 
.INC $netlists_path/codegen_refgen.spi NOPRINT 
.INC $netlists_path/codegen_devices.spi NOPRINT 


*** MODELS ***
.INC $model_path/models_$process NOPRINT


*** PARAMETERS ***
.PARAM pvdds $vdds
.PARAM pvdd  $vdd

.TEMP $temp


*** COMPONENTS ***
VDDS VDDS 0 pvdds
VDD  VDD  0 pvdd
VSS  VSS  0 0

rEXT PAD_EXT 0 $res

*** VDDS PAD     VSS CODEGEN_PSLICE 
XP1 VDDS PAD_EXT VSS CODEGEN_PSLICE M=$pslices

*** VDDS PAD         VSS CODEGEN_PSLICE 
XP2 VDDS PAD_REPLICA VSS CODEGEN_PSLICE M=$pslices

** PAD         VDDS VSS CODEGEN_NSLICE 
XN PAD_REPLICA VDDS VSS CODEGEN_NSLICE M=$nslices

**   VDDS VREF VSS CODEGEN_REFGEN
XREF VDDS VREF VSS CODEGEN_REFGEN

**     Y  PAD     VDD VSS ISOINHV VDDS VBBNW EN BIAS2 ISOINHV_ CODEGEN_COMPARATOR
XPCOMP YP PAD_EXT VDD VSS ISOINHV VDDS VBBNW EN VREF  ISOINHV_ CODEGEN_COMPARATOR

**     Y  PAD         VDD VSS ISOINHV VDDS VBBNW EN BIAS2 ISOINHV_ CODEGEN_COMPARATOR
XNCOMP YN PAD_REPLICA VDD VSS ISOINHV VDDS VBBNW EN VREF  ISOINHV_ CODEGEN_COMPARATOR
        
vISOINHV  ISOINHV  0 0
vISOINHV_ ISOINHV_ 0 'pvdds'
vEN EN 0 'pvdd'

cYP YP 0 1f
cYN YN 0 1f


*** ANALYSIS ***
.OP

.MEA OP VYP MAX 'V(YP)'
.MEA OP VYN MAX 'V(YN)'
.MEA OP VPADP MAX 'V(PAD_EXT)'
.MEA OP VPADN MAX 'V(PAD_REPLICA)'



.END";
close(DECK);
!(system("/apps/ame/bin/spice3 $deck >& /dev/null ")) || die "Spice simulation for $deck failed\n";


chomp(my $vcompp=(split('=',`/bin/grep ^VYP $deck.prt`))[1]);
chomp(my $vcompn=(split('=',`/bin/grep ^VYN $deck.prt`))[1]);

#printf("V(PComp) = %.3f   V(NComp) = %.3f\n",$vcompp,$vcompn);
#printf("V(PAD_P) = %.3f   V(PAD_N) = %.3f\n",(split('=',`/bin/grep ^VPADP $deck.prt`))[1],(split('=',`/bin/grep ^VPADN $deck.prt`))[1]);
#printf("P Slices = %-5d   N Slices = %d\n\n",$pslices,$nslices);

my $incp = ( ($vcompp > 0.5) ? 0 : 1 );
my $incn = ( ($vcompn < 0.5) ? 0 : 1 );

$pout=$pslices if($incp==0);
$nout=$nslices if($incn==0);

$pslices += ( ($incp==1) ? 1 : -1 );
$nslices += ( ($incn==1) ? 1 : -1 );

#print "IncP = $incp  IncN = $incn  \nPout = $pout  Nout = $nout\n\n";

}; 


$pout=$alwayson if($pout<$alwayson);
$pout=$totalslices if($pout>$totalslices);

$nout=$alwayson if($nout<$alwayson);
$nout=$totalslices if($nout>$totalslices);


#=================
# Print Code File
#=================
my $code="${process}_${temp}_${vdds}_${res}.truecode";

print "    Pslices = $pout  Nslices = $nout\n";
print "    Generating Code file : $code\n\n";

# Subtract Always-On Slices
my $pcode_dec = $pout - $alwayson;
my $ncode_dec = $nout - $alwayson;

# Convert decimal codes to binary and reversal can be done to align the Voltage MSB with last element of list (Not done here)
my @pcode=split(//,sprintf("%0${bits}b",$pcode_dec));
my @ncode=split(//,sprintf("%0${bits}b",$ncode_dec));

# Output binary codes as voltage sources
open(CODEFILE,">./$code") || die "Failed to open $code in write mode\n";
print CODEFILE 
"** Truecode file for GS70 mDDR/DDR2/DDR3 IO (bcshtltcscdvpbfz_*) 
** Process      : $process
** Temp         : ${temp}C
** VDDS         : ${vdds}V
** Training Res : ${res}ohms
** Pslices ON   : $pcode_dec [@pcode]
** Nslices ON   : $ncode_dec [@ncode] 

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
close(CODEFILE);
            }
        }
    }
}

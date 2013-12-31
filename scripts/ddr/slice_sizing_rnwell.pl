#!/usr/bin/perl -w
# This script helps to decide the NMOS and PMOS sizes for a given min L and min W for output resistor in DDR IO slice
#
use strict;



#============
# Parameters 
#============
# Target Impedence is the max impedence supported
my $targimp=48;
my $errimp=50;
# Length and Width of the Resistor
my $minl=1.9;
my $minw=2.4;
# File locations
my $modelpath="/proj/gateway/products/gs70/spice_models/archive/2009.04.09";
my $path="/proj/gateway4/products/gs70/expts/a0393831/SIMULATIONS/ddr/slice_sizing/res_siblk";

my $component="RES_NWELL";
my $numslices;


#======================================================================================
# Resistance of the resistor is measured by applying a very low voltage across R_NWELL 
# to minimise the current passing through the Bulk. Hence pvdds in this deck is 0.1
# Model is weak_eol to obtain max resistance
# "devices.spi" has primarily been included for model information
#======================================================================================
my $deck="$path/reseval.deck";
open(RES,">$deck");
print RES "** Setup for evaluating the resistance of resistor with the specified length and width
**
*** OPTIONS ***
.INC /proj/gateway/products/gs70/spice_models/spice_options NOPRINT

*** NETLISTS ***
.INC ${path}/devices.spi NOPRINT

*** MODELS ***
.INC ${modelpath}/models_weak_eol NOPRINT

*** PARAMETERS ***
.PARAM pvdds 0.1
.TEMP 125

*** COMPONENTS ***
VDDS VDDS 0 pvdds
VVSS VSS  0 0

.subckt TXintg_ballastr VSS NEG POS  
XRR0 VSS POS NEG RES_NWELL w=#${minw}# multFactor=1 semiResL=#${minl}# semiResHeadNum=1 model=RES_NWELL_MATCH_1118C014M parasiticL=#${minl}+0.2# 
.ends TXintg_ballastr
X1 VSS 0 VDDS TXintg_ballastr 

*** ANALYSIS ***
.OP
.MEA OP RES MAX #ABS(pvdds/I(VDDS))#

.END
";
close(RES);

# Simulating the deck and checking for success
if(system("/apps/ame/bin/spice3 $deck >& /dev/null")!=0){
	print "Spice sim failed for deck $deck \n";
	exit(1);
}
# Extracting result from .prt file
my ($maxr)=(`/bin/grep ^RES ${deck}.prt` =~ /(\S+$)/);


# Opening the output files for writing
open(DSN,">designChoose_${component}_W${minw}_L${minl}.txt");
printf DSN "---------------------\n";
printf DSN "RES Width   : %7.2f   um\n",$minw;
printf DSN "RES Length  : %7.2f   um\n",$minl;
printf DSN "---------------------\n\n";

open(LAY,">layoutChoose_${component}_W${minw}_L${minl}.txt");
printf LAY "---------------------\n";
printf LAY "RES Width   : %7.2f   um\n",$minw;
printf LAY "RES Length  : %7.2f   um\n",$minl;
printf LAY "---------------------\n\n";

open(DAT,">Choose_${component}_W${minw}_L${minl}.data");
printf DAT "---------------------\n";
printf DAT "RES Width   : %7.2f   um\n",$minw;
printf DAT "RES Length  : %7.2f   um\n",$minl;
printf DAT "---------------------\n\n";


for($numslices=39;$numslices<=44;$numslices++){
print "Computing for $numslices slices...\n";
# Calculating impedence of a single-slice from given number of slices 
# and target impedence and comparing it with that of the resistor
my $sliceimp=$targimp*$numslices;
if($sliceimp<=$maxr){
	print "Slice Imp=${sliceimp}, Res Imp=${maxr}. Not possible with $numslices Slices\n";
	next;
}


#===============================================================================================================
# In this setup, PMOS and NMOS widths are varied to see if PU and PD impedences can meet the target impedence
# This is done by connecting an ideal R between PAD and VDDS/GND and identifying the point when V(PAD)='vdds/2'
# "devices.spi" has primarily been included for model information
#===============================================================================================================
$deck="${path}/moseval.deck";
open(DECK,">$deck");
print DECK "** Setup for varying PMOS and NMOS widths to see if PU and PD impedences can meet the target impedence
**
*** OPTIONS ***
.INC /proj/gateway/products/gs70/spice_models/spice_options NOPRINT

*** NETLISTS ***
.INC ${path}/devices.spi NOPRINT

*** MODELS ***
.INC ${modelpath}/models_weak_eol NOPRINT

*** PARAMETERS ***
.PARAM pvdds 1.35
.TEMP 125
.PARAM pwidth 1

*** COMPONENTS ***
VDDS VDDS 0 pvdds
VSS VSS 0 0

VPSIG VPSIG 0 0
VNSIG VNSIG 0 pvdds

RP PADP 0 $sliceimp
RN PADN VDDS $sliceimp

.subckt TXintg_driver_onefinger PADN PADP VDDS VNSIG VPSIG VSS
XRR0 VSS PADP PINTM RES_NWELL w=#${minw}# multFactor=1 semiResL=#${minl}# semiResHeadNum=1 model=RES_NWELL_MATCH_1118C014M parasiticL=#${minl}+0.2# 
XRR1 VSS PADN NINTM RES_NWELL w=#${minw}# multFactor=1 semiResL=#${minl}# semiResHeadNum=1 model=RES_NWELL_MATCH_1118C014M parasiticL=#${minl}+0.2#
XMMP1 VDDS PINTM VPSIG VDDS VSS PCH_1P8V_HP miX=1 wFinger=#1*pwidth# l=120e-3 mi=1 cps=65e-3 model=PCH_1P8V_HP_1118C014M adasNum=1 osdNum=1 adNum=0 asNum=0 asdNum=0 assNum=0
XMMN1 VSS NINTM VNSIG VSS NCH_1P8V_HP model=NCH_1P8V_HP_1118C014M wFinger=#1*pwidth# l=120e-3 adasNum=1 osdNum=1 mi=1 cps=65e-3 adNum=0 asNum=0 asdNum=0 assNum=0 miX=1
.ends TXintg_driver_onefinger
X1 PADN PADP VDDS VNSIG VPSIG VSS TXintg_driver_onefinger 

*** ANALYSIS ***
.DC pwidth 0.8 70 0.1
.MEA DC PMOS_WIDTH WHEN V(PADP)=#pvdds/2# CROSS=1
.MEA DC NMOS_WIDTH WHEN V(PADN)=#pvdds/2# CROSS=1

.END
";
close(DECK);

# Simulating the deck and checking for success
if(system("/apps/ame/bin/spice3 $deck >& /dev/null")!=0){
	print "Looks like MOS is too small or too big for $numslices slices\n";
	next;
}
# Extracting results from .prt file
my ($pwidth)=(`/bin/grep ^PMOS_WIDTH ${deck}.prt` =~ /(\S+$)/);
my ($nwidth)=(`/bin/grep ^NMOS_WIDTH ${deck}.prt` =~ /(\S+$)/);


#=========================================================================
# In this setup the maximum impedences of the PMOS and NMOS is calculated
# Also calculated are the maximum ratios of (P/N)MOS : RES Impedence
#=========================================================================
$deck="$path/moscurve.deck";
open(DECK,">$deck");
print DECK "** Setup For Getting MOS Curve
**
*** OPTIONS ***
.INC /proj/gateway/products/gs70/spice_models/spice_options NOPRINT

*** NETLISTS ***
.INC ${path}/devices.spi NOPRINT

*** MODELS ***
.INC ${modelpath}/models_weak_eol NOPRINT 

***PARAMETERS ***
.PARAM pvdds 1.35
.TEMP 125
.PARAM ppwidth $pwidth
.PARAM pnwidth $nwidth

*** COMPONENTS ***
VDDS VDDS 0 pvdds
VSS VSS 0 0

VPSIG VPSIG 0 0
VNSIG VNSIG 0 pvdds

VSWEEP SWEEP 0 0
RSWP SWEEP 0 1MEG
EPADP PADP 0 SWEEP 0 1 
EPADN PADN 0 SWEEP 0 1

.subckt TXintg_driver_onefinger PADN PADP VDDS VNSIG VPSIG VSS
XRR0 VSS PADP PINTM RES_NWELL w=#${minw}# multFactor=1 semiResL=#${minl}# semiResHeadNum=1 model=RES_NWELL_MATCH_1118C014M parasiticL=#${minl}+0.2# 
XRR1 VSS PADN NINTM RES_NWELL w=#${minw}# multFactor=1 semiResL=#${minl}# semiResHeadNum=1 model=RES_NWELL_MATCH_1118C014M parasiticL=#${minl}+0.2#
XMMP1 VDDS PINTM VPSIG VDDS VSS PCH_1P8V_HP miX=1 wFinger=#1*ppwidth# l=120e-3 mi=1 cps=65e-3 model=PCH_1P8V_HP_1118C014M adasNum=1 osdNum=1 adNum=0 asNum=0 asdNum=0 assNum=0
XMMN1 VSS NINTM VNSIG VSS NCH_1P8V_HP model=NCH_1P8V_HP_1118C014M wFinger=#1*pnwidth# l=120e-3 adasNum=1 osdNum=1 mi=1 cps=65e-3 adNum=0 asNum=0 asdNum=0 assNum=0 miX=1
.ends TXintg_driver_onefinger
X1 PADN PADP VDDS VNSIG VPSIG VSS TXintg_driver_onefinger  

*** ANALYSIS ***
.DC VSWEEP 0 pvdds 0.01
.PUN DC #ABS(I(EPADP))#
.PUN DC #ABS(I(EPADN))#
.MEA DC IMPP FIND #pvdds/2/ABS(I(EPADP))# AT=#0.5*pvdds#
.MEA DC PERPRES FIND #(V(X1.PINTM)-pvdds/2)/(pvdds/2)*100# AT=#0.5*pvdds#
.MEA DC IMPN FIND #pvdds/2/ABS(I(EPADN))# AT=#0.5*pvdds#
.MEA DC PERNRES FIND #(pvdds/2-V(X1.NINTM))/(pvdds/2)*100# AT=#0.5*pvdds#

.END
";
close(DECK);

if(system("/apps/ame/bin/spice3 $deck >& /dev/null")!=0){
	print "Spice sim failed for deck $deck \n";
	exit(1);
}
my ($pimp)=(`/bin/grep ^IMPP ${deck}.prt` =~ /(\S+$)/);
my ($nimp)=(`/bin/grep ^IMPN ${deck}.prt` =~ /(\S+$)/);
my ($perpr)=(`/bin/grep ^PERPRES ${deck}.prt` =~ /(\S+$)/);
my ($pernr)=(`/bin/grep ^PERNRES ${deck}.prt` =~ /(\S+$)/);


my $punchfile="${deck}.pun";
my $file="${path}/moscurve.k";
my $range=0.9/2;
open(FILE,">$file") || die "Failed to open $file in write mode";
print FILE "/* Codac File to Find the Coff of Linearity */\n";
print FILE "main()\n";
print FILE "{\n";
print FILE "waveform v;\n";
print FILE "float coff;\n";
print FILE "string ifile=\"$punchfile\";\n";
print FILE "\n";
print FILE "readspicepunch(ifile);\n";
print FILE "\n";
print FILE "v=readwave(ifile,\"MATHABS(I(EPADP))\");\n";
print FILE "coff=average(wabs((1/diff(v)+$pimp)/(1/diff(v)-$pimp)),$range,0.9);\n";
print FILE "printf(\"AVGCOFFP = %g\\n\",coff);\n";
print FILE "\n";
print FILE "\n";
print FILE "v=readwave(ifile,\"MATHABS(I(EPADN))\");\n";
print FILE "coff=average(wabs((1/diff(v)-$nimp)/(1/diff(v)+$nimp)),0,$range);\n";
print FILE "printf(\"AVGCOFFN = %g\\n\",coff);\n";
print FILE "\n";
print FILE "freepunchfile(ifile);\n";
print FILE "return(0);\n";
print FILE "}\n";
close(FILE);

if(system("/apps/dad_sys/codac/bin/codac $file > ${file}.prt")!=0){
	print "Codac failed for $file \n";
	exit(1);
}
my ($pcoff)=(`/bin/grep ^AVGCOFFP ${file}.prt` =~ /(\S+$)/);
my ($ncoff)=(`/bin/grep ^AVGCOFFN ${file}.prt` =~ /(\S+$)/);


#=========================================================================
# In this setup the minimum impedences of the PMOS and NMOS is calculated
# Also calculated are the minimum ratios of (P/N)MOS : RES Impedence
#=========================================================================
$deck="$path/moscurvex.deck";
open(DECK,">$deck");
print DECK "** Setup for getting MOS curve
**
*** OPTIONS ***
.INC /proj/gateway/products/gs70/spice_models/spice_options NOPRINT

*** NETLISTS ***
.INC ${path}/devices.spi NOPRINT

*** MODELS ***
.INC ${modelpath}/models_strong NOPRINT

*** PARAMETERS ***
.PARAM pvdds 1.98
.TEMP -40
.PARAM ppwidth $pwidth
.PARAM pnwidth $nwidth

*** COMPONENTS ***
VDDS VDDS 0 pvdds
VSS VSS 0 0

VPSIG VPSIG 0 0
VNSIG VNSIG 0 pvdds
VSWEEP SWEEP 0 0
RSWP SWEEP 0 1MEG
EPADP PADP 0 SWEEP 0 1 
EPADN PADN 0 SWEEP 0 1

.subckt TXintg_driver_onefinger PADN PADP VDDS VNSIG VPSIG VSS
XRR0 VSS PADP PINTM RES_NWELL w=#${minw}# multFactor=1 semiResL=#${minl}# semiResHeadNum=1 model=RES_NWELL_MATCH_1118C014M parasiticL=#${minl}+0.2# 
XRR1 VSS PADN NINTM RES_NWELL w=#${minw}# multFactor=1 semiResL=#${minl}# semiResHeadNum=1 model=RES_NWELL_MATCH_1118C014M parasiticL=#${minl}+0.2#
XMMP1 VDDS PINTM VPSIG VDDS VSS PCH_1P8V_HP miX=1 wFinger=#1*ppwidth# l=120e-3 mi=1 cps=65e-3 model=PCH_1P8V_HP_1118C014M adasNum=1 osdNum=1 adNum=0 asNum=0 asdNum=0 assNum=0
XMMN1 VSS NINTM VNSIG VSS NCH_1P8V_HP model=NCH_1P8V_HP_1118C014M wFinger=#1*pnwidth# l=120e-3 adasNum=1 osdNum=1 mi=1 cps=65e-3 adNum=0 asNum=0 asdNum=0 assNum=0 miX=1
.ends TXintg_driver_onefinger
X1 PADN PADP VDDS VNSIG VPSIG VSS TXintg_driver_onefinger  

*** ANALYSIS ***
.DC VSWEEP 0 pvdds 0.01
.PUN DC #ABS(I(EPADP))#
.PUN DC #ABS(I(EPADN))#
.MEA DC IMPP FIND #pvdds/2/ABS(I(EPADP))# AT=#0.5*pvdds#
.MEA DC PERPRES FIND #(V(X1.PINTM)-pvdds/2)/(pvdds/2)*100# AT=#0.5*pvdds#
.MEA DC IMPN FIND #pvdds/2/ABS(I(EPADN))# AT=#0.5*pvdds#
.MEA DC PERNRES FIND #(pvdds/2-V(X1.NINTM))/(pvdds/2)*100# AT=#0.5*pvdds#

.END
";
close(DECK);

if(system("/apps/ame/bin/spice3 $deck >& /dev/null")!=0){
	print "Spice sim failed for deck $deck \n";
	exit(1);
}
my ($pimpx)=(`/bin/grep ^IMPP ${deck}.prt` =~ /(\S+$)/);
my ($nimpx)=(`/bin/grep ^IMPN ${deck}.prt` =~ /(\S+$)/);
my ($perprx)=(`/bin/grep ^PERPRES ${deck}.prt` =~ /(\S+$)/);
my ($pernrx)=(`/bin/grep ^PERNRES ${deck}.prt` =~ /(\S+$)/);

# npx/nnx are no. of slices (rounded up) required to be turned on for min PMOS/NMOS impedence
my $npx=int($pimpx/$errimp+1);
my $nnx=int($nimpx/$errimp+1);
# The difference between npx/nnx and 1 slice less is the P/N error
my $perr=($pimpx/($npx-1)-$pimpx/$npx);
my $nerr=($nimpx/($nnx-1)-$nimpx/$nnx);

printf DSN "---------------------     \n";
printf DSN "Slices      : %4d         \n",$numslices;
printf DSN "---------------------     \n";
printf DSN "PError      : %7.2f   ohms\n",$perr;
printf DSN "PSlice min  : %7.2f   ohms\n",$pimpx;
printf DSN "Pratio min  : %7.2f   perc\n",$perprx;
printf DSN "PSlice max  : %7.2f   ohms\n",$pimp;
printf DSN "Pratio max  : %7.2f   \%  \n",$perpr;
printf DSN "PCoeff      :	 %6.4f    \n",$pcoff;
printf DSN "PMOS width  : %7.2f   um  \n",$pwidth;
printf DSN "PTOTAL area : %7.2f   um2 \n",$pwidth*$npx+$minl*$minw;
printf DSN "NError      : %7.2f   ohms\n",$nerr;
printf DSN "NSlice min  : %7.2f   ohms\n",$nimpx;
printf DSN "Nratio min  : %7.2f   perc\n",$pernrx;
printf DSN "NSlice max  : %7.2f   ohms\n",$nimp;
printf DSN "Nratio max  : %7.2f   \%  \n",$pernr;
printf DSN "NCoeff      :	 %6.4f    \n",$ncoff;
printf DSN "NMOS width  : %7.2f   um  \n",$nwidth;
printf DSN "NTOTAL area : %7.2f   um2 \n",$nwidth*$nnx+$minl*$minw;
printf DSN "---------------------     \n\n";

printf LAY "---------------------     \n";
printf LAY "Slices      : %4d         \n",$numslices;
printf LAY "---------------------     \n";
printf LAY "PMOS Width  : %7.2fum     \n",$pwidth;
printf LAY "NMOS Width  : %7.2fum     \n",$nwidth;
printf LAY "---------------------     \n\n";

printf DAT "$numslices $pwidth $nwidth $pcoff $ncoff $perr $nerr %7.2f %7.2f\n",$pwidth*$npx+$minl*$minw,$nwidth*$nnx+$minl*$minw;

}

close(DSN);
close(LAY);
close(DAT);

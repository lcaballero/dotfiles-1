# Model Template for automation script
# Created by Kartik Shenoy (a0393831)

# verilog module 
# would be picked up from libdir
verilog_model : ooschf18gv

# timescale parameter
# x/x - denotes one time step / resolution
timescale : 1ns/1ns

# timestep parameter
# format number
timestep : 100
waitstep : 0

#input/output pins
#input_pins  : Strictly input pins
#output_pins : Strictly output pins
#inout_pins  : inout pins - Strictly use L,H,Y to signify inputs and 0,1,M,X,Z to signify outputs

input_pins  : gz, sw1, sw2, rf, resselect
output_pins : pad, xoa, 
inout_pins  : xia
pin_order   : gz, resselect, sw1, sw2, pad, xia, rf, xoa

#           1234
resselect : 0000
gz        : 0011
xia       : LH00
sw1       : 0000
sw2       : 0000
rf        : 0000
pad       : 10ZZ
xoa       : 10ZZ

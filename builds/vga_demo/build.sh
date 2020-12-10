#!/bin/sh

rm vga.blif vga.bin vga.txt

set -e

#yosys -p "read_verilog -Idir../../modules/\nsynth_ice40 -blif vga.blif  -top vga -json vga.json" vga_test.sv ../../modules/vga.sv 
yosys -s buildvga.ys
nextpnr-ice40 --hx1k --json vga.json --pcf vga.pcf --asc vga.asc # run place and route
#arachne-pnr -d 1k -p vga.pcf vga.blif -o vga.txt
icepack vga.asc vga.bin
iceprog vga.bin 


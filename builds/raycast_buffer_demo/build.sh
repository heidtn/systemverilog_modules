#!/bin/sh

set -e

yosys -s build_raycast.ys
nextpnr-ice40 --hx1k --json buffer_test.json --pcf vga.pcf --asc raycast.asc # run place and route
icepack raycast.asc raycast.bin
iceprog raycast.bin 


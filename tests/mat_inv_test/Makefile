TOPLEVEL_LANG = verilog
VERILOG_SOURCES += $(shell pwd)/../../modules/mat_inv.sv
COMPILE_ARGS+=-I$(shell pwd)/../../modules/

TOPLEVEL = mat_inv
MODULE = test_mat_inv
SIM = icarus

include $(shell cocotb-config --makefiles)/Makefile.sim

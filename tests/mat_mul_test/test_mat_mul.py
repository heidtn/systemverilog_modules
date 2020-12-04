# test_mat_mul.py

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

def arr_to_fixed(array, qbits):
    return [int(i * (1<<qbits)) for i in array]

def arr_to_float(array, qbits):
    return [float(i.signed_integer / float(1<<qbits)) for i in array]

@cocotb.test()
async def test_mat_mul_simple(dut):
    """ Test that d propagates to q """

    clock = Clock(dut.i_clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    for i in range(2):
        #val = random.randint(0, 1)
        #dut.d <= val  # Assign the random value val to the input port d
        in_arr = [1.5, 2, 3, 4, 5, 6, 7, 8, 9]
        dut.i_mat1 <= arr_to_fixed([1.0, 0, 0, 0, 1, 0, 0, 0, 1], 8)
        dut.i_mat2 <= arr_to_fixed(in_arr, 8)
        await Timer(100)
        #dut._log.info(f"matcalc: {dut.mat_calc.value}")
        dut._log.info(f"imat is {arr_to_float(dut.i_mat1.value, 8)} imat2 is {arr_to_float(dut.i_mat2.value, 8)}")
        dut._log.info(f"o_done: {dut.o_done.value}")
        dut._log.info(f"omat is {arr_to_float(dut.o_mat.value, 8)}")
        await RisingEdge(dut.i_clk)
        assert dut.o_mat.value == arr_to_fixed(in_arr, 8)

        #mul.i_mat2 <= [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
        #await FallingEdge(mul.i_clk)
        #assert dut.q == val, "output q was incorrect on the {}th cycle".format(i)
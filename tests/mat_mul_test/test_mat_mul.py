# test_mat_mul.py

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
import numpy as np

QBITS = int(cocotb.top.QBITS)

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
        dut.i_mat2 <= arr_to_fixed(in_arr, QBITS)
        await Timer(100)
        #dut._log.info(f"matcalc: {dut.mat_calc.value}")
        dut._log.info(f"imat is {arr_to_float(dut.i_mat1.value, QBITS)} imat2 is {arr_to_float(dut.i_mat2.value, 8)}")
        dut._log.info(f"o_done: {dut.o_done.value}")
        dut._log.info(f"omat is {arr_to_float(dut.o_mat.value, QBITS)}")
        await RisingEdge(dut.i_clk)
        assert dut.o_mat.value == arr_to_fixed(in_arr, QBITS)

@cocotb.test()
async def test_mat_mul_negs(dut):
    """ Test that negative numbers work """

    clock = Clock(dut.i_clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    in_arr1 = [1, 2, 3, 4, -5, 6, 7, 8, 9]
    in_arr2 = [-1, 0, 0, 0, 1, 0, 0, 0, -1]
    arr1 = np.array(in_arr1).reshape(3,3)
    arr2 = np.array(in_arr2).reshape(3,3)
    dut.i_mat1 <= arr_to_fixed(in_arr1, QBITS)
    dut.i_mat2 <= arr_to_fixed(in_arr2, QBITS)
    await Timer(100)
    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)
    dut._log.info(f"omat is {arr_to_float(dut.o_mat.value, QBITS)}")
    dut._log.info(f"real correct is {np.dot(arr1, arr2)}")
    assert np.allclose(arr_to_float(dut.o_mat.value, QBITS), np.dot(arr1, arr2).flatten())
    
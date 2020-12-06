# test_pid.py

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
import numpy as np
import matplotlib.pyplot as plt

try:
    QBITS = int(cocotb.top.QBITS)
    WIDTH = int(cocotb.top.WIDTH)
except Exception:
    pass

def arr_to_fix(arr, bits):
    return [int(i * (1<<bits)) for i in arr]

def arr_to_float(arr, bits):
    try:
        arr_ints = [i.signed_integer for i in arr]
        return [float(i)/float(1<<bits) for i in arr_ints]
    except Exception:
        return arr

async def print_state(dut):
    print(f"state: {dut.state.value}")
    print(f"divide state: {dut.divider_state.value}")
    try:
        print(f"divide values: {dut.div_num.value.signed_integer}, {dut.div_denom.value.signed_integer}, {dut.div_done.value}, {dut.div_result.value.signed_integer}")
    except Exception:
        pass
    print(f"output: {arr_to_float(dut.o_mat.value, QBITS)}")
    print(f"output(raw): {dut.o_mat.value}")
    print(f"mat: {arr_to_float(dut.mat.value, QBITS)}")
    print("")

@cocotb.test()
async def test_pid(dut):
    """ Test dividing two fixed point numbers """
    clock = Clock(dut.i_clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    test_arr = [5, 7, 9, 4, 3, 8, 7, 5, 6]
    fixed_arr = arr_to_fix(test_arr, QBITS)
    print("fixed arr: ", fixed_arr)
    np_arr = np.array(test_arr).reshape(3, 3)
    print("nparr: ", np_arr)
    expected_inv = np.linalg.inv(np_arr)

    dut.i_mat <= fixed_arr
    dut.i_start <= 1
    for i in range(128):
        await RisingEdge(dut.i_clk)
        await print_state(dut)
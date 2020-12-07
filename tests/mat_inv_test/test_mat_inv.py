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

def python_sim(arr):
    augment = np.eye(3)
    therange = [2, 1]
    for i in therange:
        if(arr[i - 1][0] < arr[i][0]):
            arr[[i-1, i]] = arr[[i, i-1]]
            augment[[i-1, i]] = augment[[i, i-1]]
    print("expected after augment: \n", augment, "\n", arr)

    for i in range(3):
        for j in range(3):
            if(j != i):
                temp = arr[j, i] / arr[i, i]
                for k in range(3):
                    arr[j,k] -= arr[i,k]*temp
                    augment[j,k] -= augment[i,k]*temp
                print(f"i {i}, j {j}, temp {temp} expected after cancelling: \n", augment, "\n", arr)

    for i in range(3):
        temp = arr[i,i]
        for j in range(3):
            arr[i,j] /= temp
            augment[i,j] /= temp
        print(f"i {i}, j {j}, temp {temp} expected after inverting: \n", augment, "\n", arr)

    print("expected after inverting: \n", augment, "\n", arr)

async def print_state(dut):
    if(dut.divider_state.value == 1 or dut.divider_state.value == 2):
        return
    print(f"state: {dut.state.value} rows {dut.row.value.integer} cols {dut.col.value.integer}")
    print(f"divide state: {dut.divider_state.value}")
    try:
        print(f"divide values: {dut.div_num.value.signed_integer}, {dut.div_denom.value.signed_integer}, {dut.div_done.value}, {dut.div_result.value.signed_integer}")
    except Exception:
        pass
    print(f"output: {arr_to_float(dut.o_mat.value, QBITS)}")
    print(f"output(raw): {dut.o_mat.value}")
    print(f"mat: {arr_to_float(dut.mat.value, QBITS)}")
    print(f"mat(raw): {dut.mat.value}")
    print("")

@cocotb.test()
async def test_mat_inv(dut):
    """ Test dividing two fixed point numbers """
    clock = Clock(dut.i_clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    test_arr = [5, 7, 9, 4, 3, 8, 7, 5, 6]
    fixed_arr = arr_to_fix(test_arr, QBITS)
    print("fixed arr: ", fixed_arr)
    np_arr = np.array(test_arr, dtype=np.float).reshape(3, 3)
    print("nparr: ", np_arr)
    python_sim(np_arr)
    expected_inv = np.linalg.inv(np_arr)
    print("expected inv: ", expected_inv)

    dut.i_mat <= fixed_arr
    dut.i_start <= 1
    await RisingEdge(dut.i_clk)
    dut.i_start <= 0
    for i in range(256):
        await RisingEdge(dut.i_clk)
        await print_state(dut)
        if(dut.o_done == 1):
            break
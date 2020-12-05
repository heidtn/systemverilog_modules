# test_div.py

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

QBITS = int(cocotb.top.QBITS)
WIDTH = int(cocotb.top.WIDTH)

def sim_div(a, b, qbit):
    if(a < 0):
        a = ~a + 1
    if(b < 0):
        b = ~b + 1
    return ((int(a / b) << qbit) | (int(a % b) >> 1))

async def test_two_nums(a, b, dut):
    dut.i_num <= a
    dut.i_denom <= b
    dut.i_start <= 1
    await RisingEdge(dut.i_clk)
    dut.i_start <= 0

    for i in range(WIDTH+1):
        await RisingEdge(dut.i_clk)
    
    expected = sim_div(a, b, QBITS)
    if((a < 0) != (b < 0)):
        expected *= -1
    
    print(f"Got: {dut.o_result.value.signed_integer} Should be {expected}")
    assert dut.o_result.value.signed_integer == expected

@cocotb.test()
async def test_div(dut):
    """ Test dividing two fixed point numbers """

    clock = Clock(dut.i_clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    
    nums1 = [8.5, 4.0, 1.241412, -3, -0.5, 22, 4]
    nums2 = [3.3, -2.5, 1.5, 4.4, 1, 3.3, -1]

    n1 = 12.123
    n2 = 1.123
    num1 = int(n1 * (1<<QBITS))
    num2 = int(n2 * (1<<QBITS))

    for i in nums1:
        for j in nums2:
            num1 = int(i * (1<<QBITS))
            num2 = int(j * (1<<QBITS))
            await test_two_nums(num1, num2, dut)

    """
    dut.i_num <= num1
    dut.i_denom <= num2
    dut.i_start <= 1
    await RisingEdge(dut.i_clk)
    dut.i_start <= 0

    for i in range(WIDTH+3):
        await RisingEdge(dut.i_clk)
        print(f"i {dut.i}")
        print(f"result: {dut.o_result}")
        print(f"quotient {dut.quotient_next} accume: {dut.accum_next} ({dut.accum_next.value.signed_integer})")
        print(f"num {dut.i_num} denom: {dut.i_denom} ({dut.i_denom.value.signed_integer})")
        print("")

    print(f"final binary: {dut.o_result.value} should be {bin(sim_div(num1, num2, QBITS))}")
    print(f"final result: {float(dut.o_result.value.signed_integer)/(1<<QBITS)} should be {sim_div(num1, num2, QBITS)/(1<<QBITS)}")
    print(f"true final: {n1/n2}")
    """

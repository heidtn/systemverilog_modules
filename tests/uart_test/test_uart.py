# test_mat_mul.py

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

@cocotb.test()
async def test_uart(dut):
    """ Test that d propagates to q """

    clock = Clock(dut.i_clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    dut.i_data <= 0b10111010  # 1001000
    dut.i_wr <= 1
    await RisingEdge(dut.i_clk)
    dut.i_wr <= 0
    
    print(f"UART # val: {dut.o_uart_tx}")
    for i in range(15):
        await RisingEdge(dut.i_clk)
        print(f"UART {i} val: {dut.o_uart_tx}")
        #print(f"count: {dut.tx_count.value}")
        #print(f"baud: {dut.baud_stb.value}")
        #print(f"state: {dut.state.value}")

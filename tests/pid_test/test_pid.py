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

def cvt_fixed(num, bits):
    return int(num * (1<<bits))

def cvt_float(num, bits):
    return float(num) / float(1<<bits)

def get_mass_spring():
    return MassSpring(0.2, 0.1, 1.0, 3.0, 0.0)

def get_wheel():
    return SimpleWheel(0.1, 1.0, 5.0, 1.0)

class MassSpring:
    def __init__(self, b, m, k, startpoint, startvel):
        self.b = b
        self.m = m
        self.k = k
        self.startpoint = startpoint
        self.A = np.array([[0.0, 1.0],[-k/m, -b/m]])
        self.B = np.array([0, 1.0/m])
        self.x = np.array([startpoint, startvel])
    
    def step(self, dt, force):
        self.x += dt*(np.dot(self.A, self.x) + self.B * force)
        return self.x 

class SimpleWheel:
    def __init__(self, b, I, startpoint, startvel):
        self.b = b
        self.I = I
        self.startpoint = startpoint
        self.startvel = startvel
        self.A = np.array([[0, 1.0], [0, -b/self.I]])
        self.B = np.array([0, 1.0/I])
        self.x = np.array([startpoint, startvel])
    
    def step(self, dt, torque):
        self.x += dt*(np.dot(self.A, self.x) + self.B * torque)
        return self.x

@cocotb.test()
async def test_pid(dut):
    """ Test dividing two fixed point numbers """
    simsteps = 200
    clock = Clock(dut.i_clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    mass_spring = get_wheel()
    pts = [mass_spring.x[0]]
    print(f"Terms: {dut.kP} {dut.kI} {dut.kD}")
    curpoint = pts[0]
    for i in range(simsteps):
        dut.i_curpoint <= cvt_fixed(curpoint, QBITS)
        dut.i_setpoint <= cvt_fixed(0, QBITS)
        await Timer(1)
        await RisingEdge(dut.i_clk)
        print(f"error {cvt_float(dut.error.value.signed_integer, QBITS)}, deriv: {cvt_float(dut.deriv.value.signed_integer, QBITS)}")
        print(f"error {dut.error.value}, deriv: {dut.deriv.value}")
        print(f"output {dut.o_out.value} curpoint: {curpoint}")
        output = cvt_float(dut.o_out.value.signed_integer, QBITS)
        print(f"converted output: {output}")
        print("")
        curpoint = mass_spring.step(0.1, output)[0]
        pts.append(curpoint)
    
    forceless = get_forceless_sim(simsteps)

    plt.plot(forceless, label="forceless")
    plt.plot(pts, label="controlled")
    plt.legend()
    plt.show()

def get_forceless_sim(simsteps):
    mass_spring = get_wheel()
    pts = []
    for i in range(simsteps):
        pts.append(mass_spring.step(0.1, 0)[0])
    return pts
    
def main(): 
    pts = get_forceless_sim(400)
    plt.plot(pts)
    plt.show()

if __name__ == "__main__":
    main()

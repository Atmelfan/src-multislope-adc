# Copyright (c) 2022
# Author(s): 
# * Gustav Palmqvist <gustavp@gpa-robotics.com>
#
# SPDX-License-Identifier: CERN-OHL-S-2.0

from cocotb_test.simulator import run
import pytest
import os

dir = os.path.dirname(__file__)

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge


@cocotb.test()
async def test_dff_simple(dut):
    """ Test that d propagates to q """

    clock = Clock(dut.clk, 10, units="us")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    await FallingEdge(dut.clk)  # Synchronize with the clock
    for i in range(10):
        val = random.randint(0, 1)
        dut.d.value = val  # Assign the random value val to the input port d
        await FallingEdge(dut.clk)
        assert dut.q.value == val, "output q was incorrect on the {}th cycle".format(i)

def test_dff():
    run(
        vhdl_sources=[
            "test_axi_bridge.vhd", 
            os.path.join(dir, '..', 'axi4l_bridge.vhd')
        ],
        sim_build=os.environ.get("")
        toplevel="dff",
        module="dff_cocotb"
    )
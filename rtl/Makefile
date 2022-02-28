# Example iCEBreaker Makefile
# Learn more at https://projectf.io/posts/building-ice40-fpga-toolchain/
BUILD_DIR ?= build

# configuration
SHELL = /bin/sh
FPGA_PKG ?= sg48
FPGA_TYPE ?= up5k
PCF ?= ice40_breakout.pcf
PYTEST = pytest

VHDL_SRC = delta_sigma/sinc3.vhd spi_controller/axi4l_bridge.vhd ice40_components.vhd
COSIM_SRC = spi_controller/sim_spi.vhd

# Synthesize image
top: ${BUILD_DIR}/top.rpt ${BUILD_DIR}/top.bin

${BUILD_DIR}/%.json: %.vhd ${VHDL_SRC}
	yosys -m ghdl -ql $(subst .json,,$@)-yosys.log -p 'ghdl --std=08 $^ -e $(subst .json,,$(notdir $@)); synth_ice40 -json $@; stat'

${BUILD_DIR}/%.asc: ${BUILD_DIR}/%.json ${PCF} 
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

${BUILD_DIR}/%.rpt: ${BUILD_DIR}/%.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

${BUILD_DIR}/%.bin: ${BUILD_DIR}/%.asc
	icepack $< $@

# Cosimulation
cosim: ${BUILD_DIR}/test.so

${BUILD_DIR}/%.so: ${VHDL_SRC} ${COSIM_SRC} %.vhd
	ghdl -a --std=08 $^
	ghdl -e --std=08 -shared -o $@ $(subst .so,,$(notdir $@))
#	ghdl --elab-run --std=08 $(subst .so,,$(notdir $@)) --wave=test.ghw

# Test
test:
	export SIM=ghdl
	${PYTEST} -o log_cli=True

# Print any files cargo should rebuild for if changed
cargo: test.vhd ${VHDL_SRC} ${COSIM_SRC} ${PCF} top.vhd
	@echo
	@echo "# Commands to force cargo to rerun build.rs if HDL files has changed"
	@printf "cargo:rerun-if-changed=$(shell pwd)/%s\n" $^
	@printf "cargo:rerun-if-env-changed=%s\n" FPGA_PKG FPGA_TYPE PCF

# Clean up
clean:
	rm -f ${BUILD_DIR}/top*.json ${BUILD_DIR}/top*.asc ${BUILD_DIR}/top*.rpt ${BUILD_DIR}/top*.bin ${BUILD_DIR}/top*yosys.log ${BUILD_DIR}/test.so

all: top cosim cargo

.PHONY: all test clean cargo


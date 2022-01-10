# Example iCEBreaker Makefile
# Learn more at https://projectf.io/posts/building-ice40-fpga-toolchain/

# configuration
SHELL = /bin/sh
FPGA_PKG ?= sg48
FPGA_TYPE ?= up5k
PCF ?= ice40_breakout.pcf
ADD_SRC = delta_sigma/sinc3.vhd


top: ${BUILD_DIR}/top.rpt ${BUILD_DIR}/top.bin

${BUILD_DIR}/%.json: %.vhd ${ADD_SRC}
	yosys -m ghdl -ql $(subst .json,,$@)-yosys.log -p 'ghdl  --std=08 $^ -e $(subst .json,,$(notdir $@)); synth_ice40 -json $@; stat'

${BUILD_DIR}/%.asc: ${BUILD_DIR}/%.json ${PCF} 
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

${BUILD_DIR}/%.rpt: ${BUILD_DIR}/%.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

${BUILD_DIR}/%.bin: ${BUILD_DIR}/%.asc
	icepack $< $@

clean:
	rm -f ${BUILD_DIR}/top*.json ${BUILD_DIR}/top*.asc ${BUILD_DIR}/top*.rpt ${BUILD_DIR}/top*.bin ${BUILD_DIR}/top*yosys.log

test:
	$(MAKE) -C delta_sigma test

all: top

.PHONY: all clean


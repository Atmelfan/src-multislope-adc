# configuration
SHELL = /bin/sh

SOURCE = sinc3.vhd
TESTS = test/tb_sinc3.vhd

test:
	echo "Test"
	ghdl -a sinc3.vhd 
	ghdl -a test/tb_sinc3.vhd
	ghdl -r tb_sinc3 --wave=test/tb_sinc3.ghw --stop-time=1ms

clean:
	ghdl clean

.PHONY: test clean
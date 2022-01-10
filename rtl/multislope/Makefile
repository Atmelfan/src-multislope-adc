# configuration
SHELL = /bin/sh

SOURCE = multislope.vhd
TESTS = test/tb_multislope.vhd

test: $(SOURCE) $(TESTS)
	ghdl -a $^
	ghdl -r tb_multislope --wave=test/tb_multislope.ghw --stop-time=1ms

clean:
	ghdl clean

.PHONY: test clean
# configuration
SHELL = /bin/sh

SOURCE = sinc3.vhd
TESTS = test/tb_sinc3.vhd

check: $(SOURCE) $(TESTS)
	ghdl -s $^

analyze: $(SOURCE) $(TESTS) | check
	ghdl -a $^
	
test/tb_sinc3.ghw: analyze
	ghdl -r tb_sinc3 --wave=$@ --stop-time=1ms

test/tb_boxcar.ghw: analyze
	ghdl -r tb_boxcar --wave=$@ --stop-time=1ms

test/tb_sampler.ghw: analyze
	ghdl -r tb_sampler --wave=$@ --stop-time=1ms

test: test/tb_sinc3.ghw 

clean:
	ghdl clean

.PHONY: test clean check
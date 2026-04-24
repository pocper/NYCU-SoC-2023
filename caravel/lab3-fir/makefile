PATH_LOG = ./log


Target: compile simulate clean

compile:
	iverilog -o fir.vvp bram.v fir.v fir_tb.v

simulate:
	mkdir -p $(PATH_LOG)
	vvp fir.vvp | tee $(PATH_LOG)/simulation.log

clean:

	rm -f *.vvp
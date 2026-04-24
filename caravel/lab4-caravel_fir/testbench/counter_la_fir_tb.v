// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

// --------- [Macro C define] ----------
`define addr_WB_AXI      32'h30000000
`define addr_fir_exmem   32'h38000000
`define addr_axi_start   8'h00
`define addr_fir_control 8'h00
`define addr_data_length 8'h10
`define addr_coeff       8'h40
`define addr_axi_end     8'h7F
`define addr_axis_start  8'h80 
`define addr_fir_x       8'h80
`define addr_fir_y       8'h84
`define addr_axis_end    8'h84

`define bits_control_ap_start     8'h00 // r/w
`define bits_control_ap_done      8'h01 // r
`define bits_control_ap_idle      8'h02 // r
`define bits_control_reserved     8'h03 // r
`define bits_control_x_readyWrite 8'h04 // r/w
`define bits_control_y_readyRead  8'h05 // r

// Send data to mprj_io
`define reg_fir_exmem  (`addr_fir_exmem)

// Send data to verilog - FIR
`define reg_fir_control     (`addr_WB_AXI)
`define reg_fir_data_length (`addr_WB_AXI | `addr_data_length)
`define reg_fir_coeff       (`addr_WB_AXI | `addr_coeff)
`define reg_fir_x           (`addr_WB_AXI | `addr_fir_x)
`define reg_fir_y           (`addr_WB_AXI | `addr_fir_y)
// ---------------------------------------

module counter_la_fir_tb;
	reg clock;
	reg RSTB;
	reg CSB;

	reg power1, power2;

	wire gpio;
	wire uart_tx;
	wire [37:0] mprj_io;
	wire [15:0] checkbits;

	assign checkbits  = mprj_io[23:16];
	assign uart_tx = mprj_io[6];

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("./testbench/4-2.vcd");
		$dumpvars(0, counter_la_fir_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (400) begin
			repeat (1000) @(posedge clock);
		end
		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Test LA (GL) Failed");
		`else
			$display ("Monitor: Timeout, Test LA (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	// Timer
	integer tic, toc;
	parameter times_rerun = 3;
	reg [6:0] times;
	initial begin
		for(times = 0; times < times_rerun; times = times + 1) begin
			wait(checkbits == 8'hA5);
			tic = $time; toc = 0;
			$display("----- Times#%2d -----", times+1);
			$display("Start latency-timer");
			wait(checkbits == 8'h5A);
			toc = $time;
			$display("Stop latency-timer");
			$display("Elapsed time: %10d [ns]", (toc-tic));
			$display("--------------------");
		end
	end

	reg signed [7:0] tap[10:0];
	reg signed [6:0] i;
	integer golden_ans; 
	initial begin
		tap[0] = 0;
		tap[1] = -10;
		tap[2] = -9;
		tap[3] = 23;
		tap[4] = 56;
		tap[5] = 63;
		tap[6] = 56;
		tap[7] = 23;
		tap[8] = -9;
		tap[9] = -10;
		tap[10] = 0;
		golden_ans = 0;
		for(i=0;i<11;i=i+1) begin
			golden_ans += tap[i]*(63-i);
		end
	end

	initial begin
		repeat(times_rerun) begin
			wait(checkbits == 8'hA5);
			wait(checkbits == 8'h5A);
			$display("%7s, ans = %d, golden_ans = %d\n", (mprj_io[31:24]==golden_ans[7:0])?"Correct":"Error",mprj_io[31:24], golden_ans[7:0]);
		end
		$finish;
	end

	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		RSTB <= 1'b1;	    	// Release reset
		#170000;
		CSB = 1'b0;		// CSB can be released
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD1V8;
	wire VDD3V3;
	wire VSS;
    
	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	assign mprj_io[3] = 1;  // Force CSB high.
	assign mprj_io[0] = 0;  // Disable debug mode

	caravel uut (
		.clock    (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("./testbench/counter_la_fir.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

	// Testbench UART
	tbuart tbuart (
		.ser_rx(uart_tx)
	);

endmodule
`default_nettype wire

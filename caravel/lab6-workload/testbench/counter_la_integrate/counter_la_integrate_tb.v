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

`default_nettype wire

`timescale 1 ns / 1 ps

module counter_la_integrate_tb;
	reg clock;
    reg RSTB;
	reg CSB;

	reg power1, power2;

	wire gpio;
	wire [37:0] mprj_io;
	wire [15:0] checkbits;
	wire uart_tx;
	wire uart_rx;
	reg tx_start;
	reg [7:0] tx_data;
	wire tx_busy;
	wire tx_clear_req;
    wire [7:0] rx_data;
    wire rx_finish;

	assign checkbits  = mprj_io[31:16];
	assign uart_tx = mprj_io[6];
	assign mprj_io[5] = uart_rx;

    integer pass_fir, pass_mm, pass_qs, pass_uart;
    reg [15:0] result_mm [15:0];
    reg [15:0] result_qs [9:0];
    reg [15:0] result_fir [10:0];

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
        tx_start = 0;
        tx_data = 0;
	end

	initial begin
		$dumpfile("counter_la_integrate.vcd");
		$dumpvars(0, counter_la_integrate_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (800) begin
			repeat (1000) @(posedge clock);
			// $display("+1000 cycles");
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

    initial begin
        result_mm[0]  = 62;
        result_mm[1]  = 68;
        result_mm[2]  = 74;
        result_mm[3]  = 80;
        result_mm[4]  = 62;
        result_mm[5]  = 68;
        result_mm[6]  = 74;
        result_mm[7]  = 80;
        result_mm[8]  = 62;
        result_mm[9]  = 68;
        result_mm[10] = 74;
        result_mm[11] = 80;
        result_mm[12] = 62;
        result_mm[13] = 68;
        result_mm[14] = 74;
        result_mm[15] = 80;
    end

    initial begin
        result_qs[0] = 16'h0028; // 40
        result_qs[1] = 16'h037D; // 893
        result_qs[2] = 16'h09ED; // 2541
        result_qs[3] = 16'h0A6D; // 2669
        result_qs[4] = 16'h0CA1; // 3233
        result_qs[5] = 16'h10AB; // 4267
        result_qs[6] = 16'h120E; // 4622
        result_qs[7] = 16'h1631; // 5681
        result_qs[8] = 16'h1787; // 6023
        result_qs[9] = 16'h2371; // 9073
    end

    initial begin
        result_fir[0]  = 16'h000;
        result_fir[1]  = 16'hFFF6;
        result_fir[2]  = 16'hFFE3;
        result_fir[3]  = 16'hFFE7;
        result_fir[4]  = 16'h0023;
        result_fir[5]  = 16'h009E;
        result_fir[6]  = 16'h0151;
        result_fir[7]  = 16'h021B;
        result_fir[8]  = 16'h02DC;
        result_fir[9]  = 16'h0393;
        result_fir[10] = 16'h044a;
    end

	initial begin
        pass_fir = 0;
        pass_mm = 0;
        pass_qs = 0;
        pass_uart = 0;
        wait(checkbits == 16'hAB00);
		fork
			matmul;
			qsort;
			fir;
			uart;
		join
        wait(checkbits == 16'hAB40);

        $display("=============================");
        $display("PASS/TOTAL");
        $display("matmul: %2d/%2d", pass_mm, 16);
        $display("qsort:  %2d/%2d", pass_qs, 10);
        $display("fir:    %2d/%2d", pass_fir, 11);
        $display("uart:   %2d/%2d", pass_uart, 2);
        $display("=============================");
		$finish;
	end

	task matmul;
	begin
        integer i;
		// Matrix Multiplication
		$display("Test started - Matrix Multiplication");
        $display("Waiting for the start flag (0xAB11)");
		wait(checkbits == 16'hAB11); // Start Flag
        $display("Received the start flag = 0x%x", checkbits);

        for(i=0;i<16;i=i+1) begin
		    wait(checkbits == result_mm[i]);
            pass_mm = pass_mm + 1;
            $display("[PASS] PAT%2d - matmul, exp: 0x%x, received: 0x%x", i, result_mm[i], checkbits);
        end

        $display("Waiting for the end flag (0xAB19)");
		wait(checkbits == 16'hAB19); // End Flag
        $display("Received the end flag = 0x%x", checkbits);
		$display("Test End - Matrix Multiplication\n");
	end
	endtask

	task qsort;
	begin
        integer i;
		// Q-sort
		$display("Test started - Quick Sort");
        $display("Waiting for the start flag (0xAB21)");
		wait(checkbits == 16'hAB21); // Start Flag
        $display("Received the start flag = 0x%x", checkbits);

		for(i=0;i<10;i=i+1) begin
            wait(checkbits == result_qs[i]);
            pass_qs = pass_qs + 1;
            $display("[PASS] PAT%2d - qsort, exp: 0x%x, received: 0x%x", i, result_qs[i], checkbits);
        end

        $display("Waiting for the end flag (0xAB29)");
		wait(checkbits == 16'hAB29); // End Flag
        $display("Received the end flag = 0x%x", checkbits);
		$display("Test End - Quick Sort\n");
	end
	endtask

	task fir;
	begin
        integer i;
		// FIR
		$display("Test started - FIR");
        $display("Waiting for the start flag (0xAB31)");
		wait(checkbits == 16'hAB31); // Start Flag
        $display("Received the start flag = 0x%x", checkbits);

        for(i=0;i<11;i=i+1) begin
		    wait(checkbits == result_fir[i]);
            pass_fir = pass_fir + 1;
            $display("[PASS] PAT%2d - FIR, exp: 0x%x, received: 0x%x", i, result_fir[i], checkbits);
        end

        $display("Waiting for the end flag (0xAB29)");
		wait(checkbits == 16'hAB39); // End Flag
        $display("Received the end flag = 0x%x", checkbits);
		$display("Test End - FIR\n");
	end
	endtask

	task uart;
	begin
        reg [7:0] tx_data_tmp;
		tx_data_tmp = 72;
        send_data(tx_data_tmp);
        wait(rx_finish==1);
        if(rx_data !== tx_data_tmp) begin
            $display("[FAIL] PAT1 - uart, exp: 0x%x, received: 0x%x", tx_data_tmp, rx_data);
            // $finish;
        end
        else begin
            $display("[PASS] PAT1 - uart, exp: 0x%x, received: 0x%x", tx_data_tmp, rx_data);
            pass_uart = pass_uart + 1;
        end

        tx_data_tmp = 83;
        send_data(tx_data_tmp);
        wait(rx_finish==1);
        if(rx_data !== tx_data_tmp) begin
            $display("[FAIL] PAT2 - uart, exp: 0x%x, received: 0x%x", tx_data_tmp, rx_data);
            // $finish;
        end
        else begin
            $display("[PASS] PAT2 - uart, exp: 0x%x, received: 0x%x", tx_data_tmp, rx_data);
            pass_uart = pass_uart + 1;
        end
	end
	endtask

	task send_data(
		input [7:0] data
	);
	begin
		@(posedge tbuart.clk);
		tx_start = 1;
		tx_data = data;
		@(posedge tbuart.clk);
		tx_start = 0;
        wait(tx_busy===1);
		wait(tx_busy===0);
		$display("Transmited data = 8'h%2x", data);
	end 
	endtask

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
		.FILENAME("counter_la_integrate.hex")
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
		.ser_rx(uart_tx),
		.tx_start(tx_start),
		.ser_tx(uart_rx),
		.tx_data(tx_data),
		.tx_busy(tx_busy),
		.tx_clear_req(tx_clear_req),
        .rx_data(rx_data),
        .rx_finish(rx_finish)
	);

endmodule
`default_nettype wire



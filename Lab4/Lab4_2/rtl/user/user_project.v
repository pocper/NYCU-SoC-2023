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
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

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


module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    // ------------------- [User Project] ------------------- //
    // Wishbone
    // reg isInterfaceReady; 
    wire wb_valid;
    assign wbs_ack_o = wready | rvalid | sm_tready | ss_tvalid;
    reg [31:0] axi_rdata, axis_rdata;
    assign wbs_dat_o = ({32{isAddr_axi_r}} & axi_rdata) | ({32{isAddr_axis_r}} & axis_rdata);
    // wbs_stb_i | wishone is valid           -> wbs_stb_i = 1
    // wbs_cyc_i | address is in user project -> wbs_cyc_i = 1
    // wbs_cyc_i = 1 need to respose wbs_ack_o = 1
    assign wb_valid = (wbs_cyc_i && wbs_stb_i);

    // Logic Analyzer
    assign la_data_out = 128'b0;

    // IOs
    assign io_out = {(`MPRJ_IO_PADS-1){1'b0}};
    assign io_oeb = {(`MPRJ_IO_PADS-1){1'b0}};

    // IRQ
    assign irq = 3'b0;

    // --------------------- [WB-decode] --------------------- //
    wire isFIR_verilog;
    // wire isFIR_exmem, isFIR_verilog;
    // assign isFIR_exmem   = wb_valid & ({wbs_adr_i[31:16],16'b0}==`addr_fir_exmem);
    // assign isFIR_verilog = wb_valid & ({wbs_adr_i[31:16],16'b0}==`addr_WB_AXI);
    assign isFIR_verilog = wb_valid & ({wbs_adr_i[31:16],16'b0}==`addr_WB_AXI);

    // ----------------------- [WB-AXI] ----------------------- //
    wire axis_clk, axis_rst_n;
    assign axis_clk = wb_clk_i;
    assign axis_rst_n = ~wb_rst_i;
    
    wire isAddr_axi, isAddr_axis;
    wire isAddr_axi_w, isAddr_axi_r;
    wire isAddr_axis_w, isAddr_axis_r;
    assign isAddr_axi  = isFIR_verilog && (`addr_axi_start<=wbs_adr_i[15:0]) && (wbs_adr_i[15:0]<=`addr_axi_end);
    assign isAddr_axis = isFIR_verilog && (`addr_axis_start<=wbs_adr_i[15:0]) && (wbs_adr_i[15:0]<=`addr_axis_end);
    assign isAddr_axi_w = (isAddr_axi & wbs_we_i);
    assign isAddr_axi_r = (isAddr_axi & ~wbs_we_i);
    assign isAddr_axis_w = (isAddr_axis & wbs_we_i);
    assign isAddr_axis_r = (isAddr_axis & ~wbs_we_i);

    // AXI-lite
    reg awvalid, wvalid;
    reg arvalid, rready;
    wire awready, arready, wready, rvalid;
    reg [11:0] awaddr, araddr;
    reg [31:0] wdata;
    wire [31:0] rdata;
    

    // AXI-lite (write)
    // Address
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            awaddr <= 0; awvalid <= 0;
        end
        else begin
            if(isAddr_axi_w) begin
                awaddr <= wbs_adr_i[11:0];
                awvalid <= 1;
            end

            if(awready) begin
                awvalid <= 0;
            end
        end
    end

    // Data
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            wdata <= 0; wvalid <= 0;
        end
        else begin
            if(isAddr_axi_w) begin
                wdata <= wbs_dat_i;
                wvalid <= 1;
            end

            if(wready) begin
                wvalid <= 0;
            end
        end
    end

    // AXI-lite (read)
    // Address
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            araddr <= 0;
            arvalid <= 0;
        end
        else begin
            if(isAddr_axi_r) begin
                araddr <= wbs_adr_i[11:0];
                arvalid <= 1;
            end

            if(arready)
                arvalid <= 0;
        end
    end

    // Data
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            rready <= 0;
            axi_rdata <= 0;
        end
        else begin
            if(isAddr_axi_r) begin
                rready <= 1;
            end
            else begin
                rready <= 0;
            end

            if(rvalid) begin
                axi_rdata <= rdata;
            end
        end
    end

    // AXI-stream
    // X[n] | firmware -> AXI-stream -> verilog - FIR
    reg        ss_tvalid;
    reg [31:0] ss_tdata;
    reg        ss_tlast;
    wire       ss_tready;

    // Y[n] | firmware <- AXI-stream <- verilog - FIR
    reg         sm_tready;
    wire        sm_tvalid;
    wire [31:0] sm_tdata;
    wire        sm_tlast;

    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            ss_tvalid <= 0;
            ss_tdata <= 0;
            ss_tlast <= 0;
        end
        else begin
            if(isAddr_axis_w) begin
                ss_tvalid <= 1;
                ss_tdata <= wbs_dat_i;
            end
            else begin
                ss_tvalid <= 0;
            end
        end
    end

    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            sm_tready <= 0;
            axis_rdata <= 0;
        end
        else begin
            if(sm_tvalid) axis_rdata <= sm_tdata;
            
            if(isAddr_axis_r) begin
                sm_tready <= 1;
            end
            else begin
                sm_tready <= 0;
            end
        end
    end

    // RAM - tap
    wire [3:0]  tap_WE;
    wire        tap_EN;
    wire [31:0] tap_Di;
    wire [11:0] tap_A;
    wire [31:0] tap_Do;

    // RAM - data
    wire [3:0]  data_WE;
    wire        data_EN;
    wire [31:0] data_Di;
    wire [11:0] data_A;
    wire [31:0] data_Do;

    // --------------------- [FIR-exmem] --------------------- //
    // wire EN_exmem;
    // wire [3:0] WE_exmem;
    // wire [31:0] data_Do_exmem;
    // assign EN_exmem = isFIR_exmem;
    // assign WE_exmem = wbs_sel_i & {4{wbs_we_i}};

    // --------------------- [Interface] --------------------- //
    // reg [3:0] counter_delay;
    // always @(posedge wb_clk_i) begin
    //     if (wb_rst_i) begin
    //         isInterfaceReady <= 1'b0;
    //         counter_delay <= 16'b0;
    //     end 
    //     else begin
    //         isInterfaceReady <= 1'b0;
    //         if (EN_exmem && !isInterfaceReady) begin
    //             if (counter_delay == DELAYS) begin
    //                 counter_delay <= 16'b0;
    //                 isInterfaceReady <= 1'b1;
    //             end 
    //             else begin
    //                 counter_delay <= counter_delay + 1;
    //             end
    //         end
    //     end
    // end

    // exmem - FIR
    // bram bram_fir_exmem (
    //     .CLK(wb_clk_i),
    //     .WE0(WE_exmem),
    //     .EN0(EN_exmem),
    //     .Di0(wbs_dat_i),
    //     .Do0(wbs_dat_o),
    //     .A0(wbs_adr_i)
    // );

    fir fir_DUT(
        .awready(awready),
        .wready(wready),
        .awvalid(awvalid),
        .awaddr(awaddr),
        .wvalid(wvalid),
        .wdata(wdata),
        .arready(arready),
        .rready(rready),
        .arvalid(arvalid),
        .araddr(araddr),
        .rvalid(rvalid),
        .rdata(rdata),
        .ss_tvalid(ss_tvalid),
        .ss_tdata(ss_tdata),
        .ss_tlast(ss_tlast),
        .ss_tready(ss_tready),
        .sm_tready(sm_tready),
        .sm_tvalid(sm_tvalid),
        .sm_tdata(sm_tdata),
        .sm_tlast(sm_tlast),

        // ram for tap
        .tap_WE(tap_WE),
        .tap_EN(tap_EN),
        .tap_Di(tap_Di),
        .tap_A(tap_A),
        .tap_Do(tap_Do),

        // ram for data
        .data_WE(data_WE),
        .data_EN(data_EN),
        .data_Di(data_Di),
        .data_A(data_A),
        .data_Do(data_Do),

        .axis_clk(axis_clk),
        .axis_rst_n(axis_rst_n)
        );

        // RAM for tap
        bram tap_RAM (
            .CLK(axis_clk),
            .WE0(tap_WE),
            .EN0(tap_EN),
            .Di0(tap_Di),
            .A0({{20{1'b0}}, tap_A}),
            .Do0(tap_Do)
        );

        // RAM for data: choose bram11 or bram12
        bram data_RAM(
            .CLK(axis_clk),
            .WE0(data_WE),
            .EN0(data_EN),
            .Di0(data_Di),
            .A0({{20{1'b0}},data_A}),
            .Do0(data_Do)
        );
endmodule
`default_nettype wire

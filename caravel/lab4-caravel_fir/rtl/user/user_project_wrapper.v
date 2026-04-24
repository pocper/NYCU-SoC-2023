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
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
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
    output reg wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output reg [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input   [`MPRJ_IO_PADS-1:0] io_in,
    output reg [`MPRJ_IO_PADS-1:0] io_out,
    output reg [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output reg [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

/*--------------------------------------*/
/*-----------WishBone Decoder-----------*/
/*--------------------------------------*/
// counter //
wire [2:0] user_irq_m_wire ;
wire [2:0] user_irq_c_wire ;
reg wb_clk_i_c ;
reg wb_rst_i_c ;
reg wbs_stb_i_c ;
reg wbs_cyc_i_c ;
reg wbs_we_i_c ;
reg [3:0] wbs_sel_i_c ;
reg [31:0] wbs_dat_i_c ;
reg [31:0] wbs_adr_i_c ;

reg wbs_ack_o_c ;
wire wbs_ack_o_c_wire ;

reg [31:0] wbs_dat_o_c ;
wire [31:0] wbs_dat_o_c_wire ;

// Logic Analyzer Signals
reg  [127:0] la_data_in_c ;

reg [127:0] la_data_out_c ;
wire [127:0] la_data_out_c_wire ;

reg  [127:0] la_oenb_c ;

// IOs
reg  [`MPRJ_IO_PADS-1:0] io_in_c ;

reg [`MPRJ_IO_PADS-1:0] io_out_c ;
wire [`MPRJ_IO_PADS-1:0] io_out_c_wire ;

reg [`MPRJ_IO_PADS-1:0] io_oeb_c ;
wire [`MPRJ_IO_PADS-1:0] io_oeb_c_wire ;

// mprj //
reg wb_clk_i_m ;
reg wb_rst_i_m ;
reg wbs_stb_i_m ;
reg wbs_cyc_i_m ;
reg wbs_we_i_m ;
reg [3:0] wbs_sel_i_m ;
reg [31:0] wbs_dat_i_m ;
reg [31:0] wbs_adr_i_m ;

reg wbs_ack_o_m ;
wire wbs_ack_o_m_wire ;

reg [31:0] wbs_dat_o_m ;
wire [31:0] wbs_dat_o_m_wire ;

// Logic Analyzer Signals
reg  [127:0] la_data_in_m ;

reg [127:0] la_data_out_m ;
wire [127:0] la_data_out_m_wire ;

reg  [127:0] la_oenb_m ;

// IOs
reg  [`MPRJ_IO_PADS-1:0] io_in_m ;

reg [`MPRJ_IO_PADS-1:0] io_out_m ;
wire [`MPRJ_IO_PADS-1:0] io_out_m_wire ;

reg [`MPRJ_IO_PADS-1:0] io_oeb_m ;
wire [`MPRJ_IO_PADS-1:0] io_oeb_m_wire ;

// decoder //
always @(*) begin
    if ( wbs_adr_i[31:16] == 16'h3800 ) begin // 0x3800_xxxx
        wbs_cyc_i_c  = wbs_cyc_i ;      // i
        wbs_stb_i_c  = wbs_stb_i ;      // i
        wbs_we_i_c   = wbs_we_i ;       // i
        wbs_sel_i_c  = wbs_sel_i ;      // i
        wbs_adr_i_c  = wbs_adr_i ;      // i
        wbs_dat_i_c  = wbs_dat_i ;      // i
        wbs_ack_o    = wbs_ack_o_c_wire ;    // o
        wbs_dat_o    = wbs_dat_o_c_wire ;    // o
        la_data_in_c = la_data_in ;     // i
        la_data_out  = la_data_out_c_wire ;  // o
        la_oenb_c    = la_oenb ;        // i
        io_in_c      = io_in ;          // i 
        io_out       = io_out_c_wire ;       // o
        io_oeb       = io_oeb_c_wire ;       // o
        user_irq     = user_irq_c_wire ;     // o
        // if (wbs_ack_o) begin
        //     $display("%d",wbs_ack_o);
        // end
    end else begin // 0x30000_xxxx
        wbs_cyc_i_m  = wbs_cyc_i ;      // i
        wbs_stb_i_m  = wbs_stb_i ;      // i
        wbs_we_i_m   = wbs_we_i ;       // i
        wbs_sel_i_m  = wbs_sel_i ;      // i
        wbs_adr_i_m  = wbs_adr_i ;      // i
        wbs_dat_i_m  = wbs_dat_i ;      // i
        wbs_ack_o    = wbs_ack_o_m_wire ;    // o
        wbs_dat_o    = wbs_dat_o_m_wire ;    // o
        la_data_in_m = la_data_in ;     // i
        la_data_out  = la_data_out_m_wire ;  // o
        la_oenb_m    = la_oenb ;        // i
        io_in_m      = io_in ;          // i 
        io_out       = io_out_m_wire ;       // o
        io_oeb       = io_oeb_m_wire ;       // o
        user_irq     = user_irq_m_wire ;     // o
    end
end



user_proj_example mprj (
`ifdef USE_POWER_PINS
	.vccd1(vccd1),	// User area 1 1.8V power
	.vssd1(vssd1),	// User area 1 digital ground
`endif

    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    // MGMT SoC Wishbone Slave
    .wbs_cyc_i(wbs_cyc_i_m),
    .wbs_stb_i(wbs_stb_i_m),
    .wbs_we_i(wbs_we_i_m),
    .wbs_sel_i(wbs_sel_i_m),
    .wbs_adr_i(wbs_adr_i_m),
    .wbs_dat_i(wbs_dat_i_m),
    .wbs_ack_o(wbs_ack_o_m_wire),
    .wbs_dat_o(wbs_dat_o_m_wire),

    // Logic Analyzer
    .la_data_in(la_data_in_m),
    .la_data_out(la_data_out_m_wire),
    .la_oenb (la_oenb_m),

    // IO Pads
    .io_in (io_in_m),
    .io_out(io_out_m_wire),
    .io_oeb(io_oeb_m_wire),

    // IRQ
    .irq(user_irq_m_wire)
);

user_proj_counter counter (
`ifdef USE_POWER_PINS
	.vccd1(vccd1),	// User area 1 1.8V power
	.vssd1(vssd1),	// User area 1 digital ground
`endif

    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    // MGMT SoC Wishbone Slave

    .wbs_cyc_i(wbs_cyc_i_c),
    .wbs_stb_i(wbs_stb_i_c),
    .wbs_we_i(wbs_we_i_c),
    .wbs_sel_i(wbs_sel_i_c),
    .wbs_adr_i(wbs_adr_i_c),
    .wbs_dat_i(wbs_dat_i_c),
    .wbs_ack_o(wbs_ack_o_c_wire),
    .wbs_dat_o(wbs_dat_o_c_wire),

    // Logic Analyzer

    .la_data_in(la_data_in_c),
    .la_data_out(la_data_out_c_wire),
    .la_oenb (la_oenb_c),

    // IO Pads

    .io_in (io_in_c),
    .io_out(io_out_c_wire),
    .io_oeb(io_oeb_c_wire),

    // IRQ
    .irq(user_irq_c_wire)
);


endmodule	// user_project_wrapper

`default_nettype wire

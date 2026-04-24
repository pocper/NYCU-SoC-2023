module exmem (
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
    wire clk;
    wire rst;

    wire valid;
    wire [3:0] wstrb;
    wire decoded;

    reg ready;

    assign valid = wbs_cyc_i && wbs_stb_i && decoded; 
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wbs_ack_o = ready;

    assign clk = wb_clk_i;
    assign rst = wb_rst_i;

    assign decoded = wbs_adr_i[31:20] == 12'h380 ? 1'b1 : 1'b0;
    
    always @(posedge clk) begin
        if (rst) begin
            ready <= 1'b0;
        end else begin
            ready <= 1'b0;
            if ( valid && !ready ) begin
                ready <= 1'b1;
            end
        end
    end

    bram user_bram (
        .CLK(clk),
        .WE0(wstrb),
        .EN0(valid),
        .Di0(wbs_dat_i),
        .Do0(wbs_dat_o),
        .A0(wbs_adr_i)
    );

endmodule
`timescale 1ns / 1ps
module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    // AXI-lite 
    output reg                     awready,
    output reg                     wready,
    input                          awvalid,
    input      [(pADDR_WIDTH-1):0] awaddr,
    input                          wvalid,
    input      [(pDATA_WIDTH-1):0] wdata,
    output reg                     arready,
    input                          rready,
    input                          arvalid,
    input      [(pADDR_WIDTH-1):0] araddr,
    output reg                     rvalid,
    output reg [(pDATA_WIDTH-1):0] rdata,    
    
    // AXI-Stream 
    input                          ss_tvalid, 
    input      [(pDATA_WIDTH-1):0] ss_tdata, 
    input                          ss_tlast, 
    output reg                     ss_tready, 
    input                          sm_tready, 
    output reg                     sm_tvalid, 
    output reg [(pDATA_WIDTH-1):0] sm_tdata, 
    output reg                     sm_tlast, 
    
    // bram for tap RAM
    output reg [3:0]               tap_WE,
    output reg                     tap_EN,
    output reg [(pDATA_WIDTH-1):0] tap_Di,
    output reg [(pADDR_WIDTH-1):0] tap_A,
    input      [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output reg [3:0]               data_WE,
    output reg                     data_EN,
    output reg [(pDATA_WIDTH-1):0] data_Di,
    output reg [(pADDR_WIDTH-1):0] data_A,
    input      [(pDATA_WIDTH-1):0] data_Do,

    input                         axis_clk,
    input                         axis_rst_n
);
begin
    // ================================== //
    //             Description            //
    // ================================== //
    // Input: data(X[n])/coefficient(a[n])/data length/ap_start
    // Process: Finite Inpulse Response(N=11) 
    // |-> Y[n] = sigma(a[n-11]*X[n])
    // Output: data(Yn)/ap_start/ap_idle/ap_done
    // ---
    // Source(master) / simulation(slave)
    // Data
    // - AXI-Lite(s->m): coefficient(a[n])/data length/ap_start
    // - AXI-Lite(s<-m): ap_start/ap_idle/ap_done
    // - AXI-Stream(s->m): data(X[n])
    // - AXI-Stream(s<-m): data(Y[n])
    // Memory
    // - coefficient(a[n])/data(X[n])
    // ================================== //
    //              parameter             //
    // ================================== //
    // | Port Level Protocol
    // - AXI-lite
    reg isInADDR_tap;
    
    // | Block Level Protocol
    // - ap_ctrl_hs
    reg ap_start, ap_done, ap_idle;
    reg [9:0] data_length;
    localparam  ADDR_ap_state = 8'h0,
                ADDR_data_length = 8'h10,
                ADDR_tap_param = 8'h20;
    
    // SRAM(Data)
    reg [3:0] data_n;
    reg isSRAMDataReady;
    reg [3:0] data_validNum;
    reg [1:0] state_data;
    localparam  state_data_stop = 0,
                state_data_read = 1,
                state_data_read_wait = 2,
                state_data_write = 3;
    
    // FIR
    reg isFIRReady;
    reg [3:0] idx_reg;
    reg [1:0] state_FIR;
    localparam  state_FIR_stop = 0,
                state_FIR_read = 1,
                state_FIR_read_wait = 2,
                state_FIR_calculate = 3;

    // ========================================= //
    //              Sequential Logic             //
    // ========================================= //
    // | Port Level Protocol
    // - AXI-lite(Write)
    // Source(master) / simulation(slave)
    // 1. awaddr  (slave->master)
    // 2. awvalid (slave->master)
    // 3. awready (master->slave)
    // 4. wdata   (slave->master)
    // 5. wvalid  (slave->master)
    // 6. wready  (master->slave)
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            awready <= 0;
            wready <= 0;
        end
        else begin
            case({awvalid, awready, wvalid, wready})
            4'b1000: awready <= 1;
            4'b1100: awready <= 0;
            4'b0010: 
                if((!tap_EN & tap_WE==4'b0000) | (tap_EN & tap_WE==4'b1000)) 
                    wready <= 1;
            4'b0011: wready <= 0;
            endcase
        end
    end

    // - AXI-lite(Read)
    // Source(master) / simulation(slave)
    // 1. araddr  (slave->master)
    // 2. arvalid (slave->master)
    // 3. arready (master->slave)
    // 4. rready  (slave->master)
    // 5. rvalid  (master->slave)
    // 6. rdata   (master->slave)
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            arready <= 0;
            rvalid <= 0;
            rdata <= 0;
            isInADDR_tap <= 0;
        end
        else begin
            case({arvalid, arready, rready, rvalid})
            4'b1000: begin
                arready <= 1;
                isInADDR_tap <= (araddr>=ADDR_tap_param);
            end
            4'b1100: begin
                // Wait data from SRAM
                arready <= 0;
            end
            4'b0010: begin
                rvalid <= 1;
                if(isInADDR_tap) begin
                    rdata <= tap_Do;
                    isInADDR_tap <= 0;
                end
                else begin
                    rdata <= {ap_idle, ap_done, ap_start};
                end
            end
            4'b0011:
                rvalid <= 0;
            endcase
        end
    end

    // | Block Level Protocol
    // - ap_ctrl_hs
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            ap_start <= 0;
            ap_done <= 0;
            ap_idle <= 1;
            data_length <= 0;
        end
        else begin
            case({awvalid, awready, wvalid, wready})
            4'b0010: begin
                case(awaddr)
                    ADDR_ap_state: begin
                        if(ap_idle) ap_start <= 1;
                        ap_idle <= 0;
                    end
                    ADDR_data_length: begin
                        data_length <= wdata;
                    end
                endcase
            end
            endcase

            if(!ap_idle) ap_start <= 0;
            if(isFIRReady) data_length <= data_length-1;
            if(sm_tlast) ap_done <= 1;
            if(sm_tlast) ap_idle <= 1;
        end
    end

    // SRAM(Data)
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            data_WE <= 0;
            data_EN <= 1;
            data_Di <= 0;
            data_A <= 0;
            data_n <= Tape_Num;
            state_data <= state_data_stop;
            isSRAMDataReady <= 0;
            data_validNum <= 0;
        end
        else begin
            case(state_data)
            state_data_stop: begin
                if(ss_tvalid & (isFIRReady|ap_start)) state_data <= state_data_read;
                if(ss_tready) begin
                    data_WE <= 0;
                    data_A <= (Tape_Num - 2)<<2;
                    data_n <= Tape_Num;
                    isSRAMDataReady <= 0;
                end
            end
            // Read SRAM_data[data_n-1]
            state_data_read: begin
                state_data <= state_data_read_wait;
            end
            // Wait data from SRAM
            state_data_read_wait: begin
                data_WE <= 1;
                data_A <= data_n<<2;
                state_data <= state_data_write;
                data_Di <= (data_n==0)?ss_tdata:data_Do;
            end
            // SRAM_data[data_n] = SRAM_data[data_n-1]
            state_data_write: begin
                data_WE <= data_WE << 1;
                
                if(data_WE==4'b1000) begin
                    if(data_n==0) begin
                        isSRAMDataReady <= 1;
                        if(data_validNum<Tape_Num) data_validNum <= data_validNum + 1;
                        state_data <= state_data_stop;
                    end
                    else begin
                        data_A <= ((data_n-1)>0)?(data_n - 2)<<2:0;
                        data_n <= data_n - 1;
                        state_data <= state_data_read;
                    end
                end
            end
            endcase

            case(state_FIR)
                state_FIR_read: begin
                    // Read Data[n]
                    data_WE <= 0;
                    data_A <= idx_reg<<2;
                end
            endcase
        end
    end

    // SRAM(Tap)
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            tap_WE <= 0;
            tap_EN <= 0;
            tap_Di <= 0;
            tap_A <= 0;
        end
        else begin
            case({awvalid, awready, wvalid, wready})
            4'b1000: begin
                if(awaddr>=ADDR_tap_param)
                    tap_A <= (awaddr-ADDR_tap_param);
            end
            4'b1100: begin
                if(awaddr>=ADDR_tap_param)
                    tap_EN <= 1;
            end
            4'b0010: begin
                if(tap_EN) begin
                    if(!tap_WE) begin
                        tap_WE <= 1;
                        tap_Di <= wdata;
                    end
                    else begin
                        tap_WE <= tap_WE << 1;
                    end
                end
            end
            4'b0011: begin
                tap_EN <= 0;
            end
            endcase

            case({arvalid, arready, rready, rvalid})
                4'b1000: begin
                    tap_EN <= 1;
                    if(araddr>=ADDR_tap_param)
                        tap_A <= (araddr-ADDR_tap_param);
                end
                4'b0011: tap_EN <= 0;
            endcase

            case(state_FIR)
            state_FIR_read: begin
                // Read Tap[n]
                tap_EN <= 1;
                tap_WE <= 0; tap_A <= idx_reg<<2;
            end
            endcase
        end
    end

    // FIR
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            idx_reg <= 0;
            sm_tdata <= 0;
            isFIRReady <= 0;
            state_FIR <= state_FIR_stop;
        end
        else begin
            case(state_FIR)
            state_FIR_stop: begin
                idx_reg <= 0;
                sm_tdata <= 0;
                if(!ap_idle & isSRAMDataReady & !isFIRReady & sm_tready)
                    state_FIR <= state_FIR_read;
                isFIRReady <= 0;
            end
            state_FIR_read: begin
                state_FIR <= state_FIR_read_wait;
            end
            // Wait data from SRAM
            state_FIR_read_wait: begin
                state_FIR <= state_FIR_calculate;
            end
            state_FIR_calculate: begin
                sm_tdata <= sm_tdata + tap_Do * data_Do;
                idx_reg <= idx_reg + 1;
                state_FIR <= (idx_reg==data_validNum-1)?state_FIR_stop:state_FIR_read;
                isFIRReady <= (idx_reg==data_validNum-1);
            end
            endcase
        end
    end

    // ========================================= //
    //             Combinational Logic           //
    // ========================================= //
    // | Port Level Protocol
    // - AXI-Stream(master<-slave)
    // Source(master) / simulation(slave)
    always @(*) begin
        ss_tready = 0;
        if({ss_tvalid, ss_tready}==3'b10)
            ss_tready = isFIRReady;
    end

    // - AXI-Stream(master->slave)
    // Source(master) / simulation(slave)
    always @(*) begin
        sm_tvalid = isFIRReady;
        sm_tlast = (isFIRReady & data_length==1);
    end
end
endmodule
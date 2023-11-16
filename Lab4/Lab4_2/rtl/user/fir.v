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
    reg isSRAM_tapReady;
    reg [1:0] SRAM_readCycle;
    
    // | Block Level Protocol
    // - ap_ctrl_hs
    reg ap_start, ap_done, ap_idle;
    wire isX_readyWrite;
    reg isY_readyRead;
    assign isX_readyWrite =  (!ap_idle & state_data==state_data_stop);
    // assign isY_readyRead = isFIRReady; // isY_readyRead = 1 when Y[n] is Ready, = 0 when is read <= =0 might change framework
    reg [9:0] data_length, data_length_init;
    localparam  ADDR_ap_state = 8'h0,
                ADDR_data_length = 8'h10,
                ADDR_tap_param = 8'h40;
    
    // SRAM(Tap)
    reg [1:0] tap_WE_shift_n;

    // SRAM(Data)
    reg [3:0] data_n;
    reg isSRAM_dataReady;
    reg [3:0] data_validNum;
    reg [1:0] state_data;
    localparam  state_data_stop = 0,
                state_data_read = 1,
                state_data_read_wait = 2,
                state_data_write = 3;
    
    // FIR
    reg isFIRReady;
    reg isFIRDoneFirst;
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
    reg isStateReady_w, isStateReady_r;
    always @(*) begin
        awready = 0; wready = 0;
        if(isSRAM_tapReady | isStateReady_w) begin
            awready = 1; wready = 1;
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
    always @(*) begin
        arready = 0; rvalid = 0;
        if(isStateReady_r) begin
            arready = 1; rvalid = 1;
        end
    end

    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            rdata <= 0;
            SRAM_readCycle <= 0;
        end
        else begin
            isStateReady_r <= 0;
            if(arvalid & rready) begin
                if(araddr[6]) begin
                    SRAM_readCycle <= SRAM_readCycle + 1;
                    if(SRAM_readCycle==1) begin
                        rdata <= tap_Do;
                        isStateReady_r <= 1;
                    end
                    if(SRAM_readCycle==2)
                        SRAM_readCycle <=0; // need to stay until transmit complete
                end
                if(araddr==0) begin // ap_state
                    isStateReady_r <= 1;
                    rdata <= {isY_readyRead, isX_readyWrite, 1'b0, ap_idle, ap_done, ap_start};
                end
            end
        end
    end

    // | Block Level Protocol
    // - ap_ctrl_hs
    reg is_data_length_minus;
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            ap_start <= 0;
            ap_idle <= 1;
            ap_done <= 0;
            data_length <= 0;
            isStateReady_w <= 0;
            is_data_length_minus <= 0;
        end
        else begin
            if(awvalid & wvalid) begin
                case(awaddr)
                    ADDR_ap_state: begin
                        if(ap_idle) ap_start <= 1;
                        ap_idle <= 0;
                        isStateReady_w <= 1;
                    end
                    ADDR_data_length: begin
                        data_length <= wdata;
                        data_length_init <= wdata;
                        isStateReady_w <= 1;
                    end
                endcase
            end
            if(isStateReady_w) isStateReady_w <= 0;
            if(!ap_idle) ap_start <= 0;
            if(!isX_readyWrite && data_length>0) is_data_length_minus<=0;
            if(isY_readyRead&!is_data_length_minus) begin
                data_length <= data_length-1;
                is_data_length_minus <= 1;
            end
            if(sm_tlast) ap_done <= 1;
            if(ap_done) begin
                ap_idle <= 1;
                ap_done <= 0;
            end
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
            isSRAM_dataReady <= 0;
            data_validNum <= 0;
        end
        else begin
            case(state_data)
            state_data_stop: begin
                if(ss_tvalid & isX_readyWrite)
                    state_data <= state_data_read;
                    data_WE <= 0;
                    data_A <= (Tape_Num - 2);
                    data_n <= Tape_Num;
                    if(sm_tready||ss_tready)
                        isSRAM_dataReady <= 0;
            end
            // Read SRAM_data[data_n-1]
            state_data_read: begin
                state_data <= state_data_read_wait;
            end
            // Wait data from SRAM
            state_data_read_wait: begin
                data_WE <= 1;
                data_A <= data_n;
                state_data <= state_data_write;
                data_Di <= (data_n==0)?ss_tdata:data_Do;
            end
            // SRAM_data[data_n] = SRAM_data[data_n-1]
            state_data_write: begin
                data_WE <= data_WE << 1;
                
                if(data_WE==4'b1000) begin
                    if(data_n==0) begin
                        isSRAM_dataReady <= 1;
                        if(data_validNum<Tape_Num) data_validNum <= data_validNum + 1;
                        state_data <= state_data_stop;
                    end
                    else begin
                        data_A <= ((data_n-1)>0)?(data_n - 2):0;
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
                    data_A <= idx_reg;
                end
            endcase
        end
    end

    // SRAM(Tap)
    always @(*) begin
        tap_EN = (awvalid & awaddr[6]) | (arvalid & araddr[6]) | (state_FIR!=state_FIR_stop); // 0x40 - 0x7F
        tap_Di = wdata;
        if(awvalid & awaddr[6])
            tap_A = awaddr[5:0]>>2;
        else if(arvalid & araddr[6])
            tap_A = araddr[5:0]>>2;

        if(state_FIR==state_FIR_read_wait)
            tap_A = idx_reg;
        tap_WE = (awvalid & awaddr[6])?(1<<tap_WE_shift_n):0;
        isSRAM_tapReady = (tap_WE_shift_n==3);
    end

    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            isSRAM_tapReady <= 0;
            tap_WE_shift_n <= 0;
        end
        else begin
            if(awvalid & awaddr[6]) begin
                tap_WE_shift_n <= tap_WE_shift_n + 1;
            end
        end
    end

    // FIR
    always @(posedge axis_clk, negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            idx_reg <= 0;
            sm_tdata <= 0;
            isFIRReady <= 1;
            isFIRDoneFirst <= 0;
            isY_readyRead <= 0;
            state_FIR <= state_FIR_stop;
        end
        else begin
            case(state_FIR)
            state_FIR_stop: begin
                idx_reg <= 0;
                if(!isSRAM_dataReady) isFIRDoneFirst <= 0;
                if(isSRAM_dataReady & !isFIRDoneFirst) begin
                    state_FIR <= state_FIR_read;
                    isFIRReady <= 0;
                end
                // ERROR 誰來收走的時候才要flasg
                // 怎麼知道資料被收走了? sm_tready & sm_tvalid就收走了
                if(sm_tvalid & sm_tready) begin
                    isY_readyRead <= 0;
                    sm_tdata <= 0;
                end
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
                isY_readyRead <= (idx_reg==data_validNum-1);
                isFIRDoneFirst <= 1;
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
        ss_tready = ss_tvalid & isFIRReady;
    end

    // - AXI-Stream(master->slave)
    // Source(master) / simulation(slave)
    always @(*) begin
        sm_tvalid = isY_readyRead;
        sm_tlast = (isFIRReady & data_length==0);
    end
endmodule
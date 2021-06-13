`timescale 1ns / 1ps

module my_pe_array #(
    parameter BRAM_ADDR_WIDTH = 32,
    parameter BRAM_DATA_WIDTH = 32,
    parameter BRAM_WE_WIDTH = 4,
    parameter BLK_WIDTH = 8,  // input block width
    parameter DONE_LENGTH = 5 // done signal duration
)(
    // AXI Connectivity
    input  start,
    output done,
    input  S_AXI_ACLK,
    input  S_AXI_ARESETN,
    
    // BRAM Connectivity
    output [BRAM_ADDR_WIDTH-1:0] BRAM_ADDR,
    input  [BRAM_DATA_WIDTH-1:0] BRAM_RDDATA,
    output [BRAM_DATA_WIDTH-1:0] BRAM_WRDATA,
    output [BRAM_WE_WIDTH-1:0]   BRAM_WE,
    output BRAM_CLK
);
    
    wire [BLK_WIDTH**2-1:0] dvalid;        // dvalid from PE array
    wire [15:0] dout [0:BLK_WIDTH**2-1];   // douts from PE array
    reg  [15:0] dout_r [0:BLK_WIDTH**2-1]; // registers holding douts
    reg  [2:0] present_state;              // state register
    reg  [2:0] next_state;                 // next state
    reg  [7:0] gb [0:BLK_WIDTH*5-1];      // global buffer (40 entries)
    reg  [BLK_WIDTH-1:0] cnt_LOAD;         // counter for load state
    wire [BLK_WIDTH-1:0] cnt_LOAD_s;       // load state counter shifted
    reg  [BLK_WIDTH-1:0] cnt_CALC;         // counter for # of multiplications
    reg  [BLK_WIDTH-1:0] cnt_HARV;         // counter for harvest state
    reg  [BLK_WIDTH-1:0] cnt_DONE;         // counter for done state
    reg  [BRAM_ADDR_WIDTH-3:0] bram_addr;  // masked BRAM address
    
    // states (IDLE -> LOAD -> CALC -> ... -> CALC -> HARV -> DONE)
    localparam S_IDLE = 3'd0, S_LOAD = 3'd1, S_CALC = 3'd2,
               S_HARV = 3'd3, S_DONE = 3'd4;

    // wire assignments
    assign done = (present_state == S_DONE);
    assign BRAM_ADDR = {bram_addr, 2'd0};
    assign BRAM_WRDATA = (present_state == S_HARV) ? 
                        {dout_r[2 * cnt_HARV + 1], dout_r[2 * cnt_HARV]} : 0;
    assign BRAM_WE = {4{(present_state == S_HARV)}};
    // assign BRAM_CLK = ~S_AXI_ACLK; // 180 degrees phase-shifted
    clk_wiz_0 u_clk (.clk_out1(BRAM_CLK), .clk_in1(S_AXI_ACLK));
    assign cnt_LOAD_s = (cnt_LOAD >> 1);
    
    // PE array
    genvar row, col;
    for (row = 0; row < BLK_WIDTH; row = row + 1) begin:PE_ROW
        for (col = 0; col < BLK_WIDTH; col = col + 1) begin:PE_COL
            my_pe PE(
                .aclk(S_AXI_ACLK),
                .aresetn(S_AXI_ARESETN & ~(
                         present_state == S_IDLE ||
                         present_state == S_HARV || 
                         present_state == S_DONE)),
                .ain(gb[BLK_WIDTH + (row << 2) + (cnt_CALC[1:0])]),
                .bin(gb[col]),
                .valid(present_state == S_CALC && next_state != S_HARV),
                .dvalid(dvalid[row * BLK_WIDTH + col]),
                .dout(dout[row * BLK_WIDTH + col])
            );
        end
    end
    
    // counters
    always @(posedge S_AXI_ACLK) begin
        cnt_LOAD <= (present_state == S_LOAD) ? cnt_LOAD + 1 : 0;
        cnt_CALC <= (present_state == S_CALC) ? cnt_CALC + 1 :
                   ((present_state == S_LOAD) ? cnt_CALC : 0);
        cnt_HARV <= (present_state == S_HARV) ? cnt_HARV + 1 : 0;
        cnt_DONE <= (present_state == S_DONE) ? cnt_DONE + 1 : 0;
    end

    // global buffer
    always @(posedge S_AXI_ACLK)
        if (present_state == S_LOAD && cnt_LOAD[0]) begin
            gb[cnt_LOAD_s * 4 + 0] <= BRAM_RDDATA[8*(0+1)-1:8*0];
            gb[cnt_LOAD_s * 4 + 1] <= BRAM_RDDATA[8*(1+1)-1:8*1];
            gb[cnt_LOAD_s * 4 + 2] <= BRAM_RDDATA[8*(2+1)-1:8*2];
            gb[cnt_LOAD_s * 4 + 3] <= BRAM_RDDATA[8*(3+1)-1:8*3];
        end

    // douts
    for (row = 0; row < BLK_WIDTH; row = row + 1) begin
        for (col = 0; col < BLK_WIDTH; col = col + 1) begin
             always @(posedge S_AXI_ACLK)
                if (cnt_CALC == BLK_WIDTH && dvalid)
                    dout_r[row * BLK_WIDTH + col] <= dout[row * BLK_WIDTH + col];
                else if (next_state == S_HARV)
                    dout_r[row * BLK_WIDTH + col] <= dout_r[row * BLK_WIDTH + col];
                else
                    dout_r[row * BLK_WIDTH + col] <= 0;
        end
    end
    
    // present_state
    always @(posedge S_AXI_ACLK)
        present_state <= (S_AXI_ARESETN) ? next_state : S_IDLE;
    
    // combinational logic for next_state
    always @(*)
        case (present_state)
            S_IDLE: next_state <= (start) ? S_LOAD : S_IDLE;
            S_LOAD: next_state <= (cnt_CALC[1:0] == 0) ?
                    ((cnt_LOAD < BLK_WIDTH * 2 + (BLK_WIDTH >> 1) - 1) ? S_LOAD : S_CALC) :
                    ((cnt_LOAD < (BLK_WIDTH >> 1 ) - 1) ? S_LOAD : S_CALC);
            S_CALC: next_state <= (cnt_CALC < BLK_WIDTH - 1) ? S_LOAD : 
                                                   ((dvalid) ? S_HARV : S_CALC);
            S_HARV: next_state <= (cnt_HARV < (BLK_WIDTH**2 >> 1) - 1) ? S_HARV : S_DONE;
            S_DONE: next_state <= (cnt_DONE < DONE_LENGTH - 1) ? S_DONE : S_IDLE;
            default: next_state <= S_IDLE;
        endcase
    
    // combinational logic for bram_addr
    always @(*) begin
        case (present_state)
            S_LOAD: bram_addr <= (cnt_LOAD_s < (BLK_WIDTH >> 2)) ?
                    BLK_WIDTH ** 2 + cnt_CALC * (BLK_WIDTH >> 2) + cnt_LOAD_s : // second matrix
                    (cnt_LOAD_s - (BLK_WIDTH >> 2)) * (BLK_WIDTH >> 2) + cnt_CALC[2]; // first matrix
            S_HARV: bram_addr <= cnt_HARV;
            default: bram_addr <= 0;
        endcase
    end
    
endmodule

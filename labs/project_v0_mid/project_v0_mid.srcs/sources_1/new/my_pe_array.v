`timescale 1ns / 1ps

module my_pe_array #(
    parameter BRAM_ADDR_WIDTH = 32,
    parameter BRAM_DATA_WIDTH = 32,
    parameter BRAM_WE_WIDTH = 4,
    parameter BLK_WIDTH = 8, // input block width
    parameter DONE_LENGTH = 5  // done signal duration
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
    
    wire [BLK_WIDTH-1:0] dvalid;           // dvalid from PE array
    reg  dvalid_r;                         // register holding davalid
    wire [31:0] dout [0:BLK_WIDTH**2-1];   // douts from PE array
    reg  [31:0] dout_r [0:BLK_WIDTH**2-1]; // registers holding douts
    reg  [2:0] present_state;              // state register
    reg  [2:0] next_state;                 // next state
    reg  [31:0] gb [0:BLK_WIDTH*2-1];      // global buffer (16 entries)
    reg  [BLK_WIDTH-1:0] cnt_LOAD;         // counter for load state
    wire [BLK_WIDTH-1:0] cnt_LOAD_s;       // cnt_LOAD shifted one bit to the right
    reg  [BLK_WIDTH-1:0] cnt_CALC;         // counter for load & calculation states
    reg  [BLK_WIDTH-1:0] cnt_TRAN;         // counter for data-transfer state
    reg  [BLK_WIDTH-1:0] cnt_DONE;         // counter for done state
    reg  [BRAM_ADDR_WIDTH-3:0] bram_addr;  // masked BRAM address
    
    // states (IDLE -> LOAD -> CALC -> ... -> WAIT -> TRAN -> DONE)
    localparam S_IDLE = 3'd0, S_LOAD = 3'd1, S_WAIT = 3'd2,
               S_CALC = 3'd3, S_TRAN = 3'd4, S_DONE = 3'd5;

    // wire assignments
    assign done = (present_state == S_DONE);
    assign BRAM_ADDR = {bram_addr, 2'd0};
    assign BRAM_WRDATA = (present_state == S_TRAN) ? dout_r[cnt_TRAN] : 0;
    assign BRAM_WE = {4{(present_state == S_TRAN)}};
    assign BRAM_CLK = ~S_AXI_ACLK; // 180 degrees phase-shifted
    assign cnt_LOAD_s = cnt_LOAD >> 1;
    
    // PE array
    genvar row, col;
    for (row = 0; row < BLK_WIDTH; row = row + 1) begin:PE_ROW
        for (col = 0; col < BLK_WIDTH; col = col + 1) begin:PE_COL
            my_pe PE(
                .aclk(S_AXI_ACLK),
                .aresetn(S_AXI_ARESETN & ~(
                         present_state == S_IDLE || 
                         present_state == S_DONE)),
                .ain(gb[row]),
                .bin(gb[BLK_WIDTH + col]),
                .valid(present_state == S_CALC),
                .dvalid(dvalid[row * BLK_WIDTH + col]),
                .dout(dout[row * BLK_WIDTH + col])
            );
        end
    end
    
    // counters
    always @(posedge S_AXI_ACLK) begin
        cnt_LOAD <= (present_state == S_LOAD) ? cnt_LOAD + 1 : 0;
        cnt_CALC <= (present_state == S_CALC) ? cnt_CALC + 1 :
            ((present_state == S_LOAD || present_state == S_WAIT) ? cnt_CALC : 0);
        cnt_TRAN <= (present_state == S_TRAN) ? cnt_TRAN + 1 : 0;
        cnt_DONE <= (present_state == S_DONE) ? cnt_DONE + 1 : 0;
    end
    
    // global buffer
    always @(posedge S_AXI_ACLK)
        gb[cnt_LOAD_s] <= (present_state == S_LOAD && cnt_LOAD[0]) ? 
            BRAM_RDDATA : gb[cnt_LOAD_s]; // save to buffer at cnt = 1, 3, 5, ...
    
    // dvalid
    always @(posedge S_AXI_ACLK)
        if (dvalid)
            dvalid_r <= 1'b1;
        else if (present_state == S_LOAD || present_state == S_WAIT)
            dvalid_r <= dvalid_r;
        else
            dvalid_r <= 1'b0;
    
    // douts
    for (row = 0; row < BLK_WIDTH; row = row + 1) begin
        for (col = 0; col < BLK_WIDTH; col = col + 1) begin
             always @(posedge S_AXI_ACLK)
                if (cnt_CALC == BLK_WIDTH && dvalid)
                    dout_r[row * BLK_WIDTH + col] <= dout[row * BLK_WIDTH + col];
                else if (next_state == S_TRAN)
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
            S_LOAD: next_state <= (cnt_LOAD < BLK_WIDTH * 2 * 2 - 1) ? S_LOAD : 
                                 ((cnt_CALC == 0 || dvalid_r) ? S_CALC : S_WAIT);
            S_WAIT: next_state <= (dvalid | dvalid_r) ? 
                                 ((cnt_CALC == BLK_WIDTH) ? S_TRAN : S_CALC) : S_WAIT;
            S_CALC: next_state <= (cnt_CALC == BLK_WIDTH - 1) ? S_WAIT : S_LOAD;
            S_TRAN: next_state <= (cnt_TRAN < BLK_WIDTH**2 - 1) ? S_TRAN : S_DONE;
            S_DONE: next_state <= (cnt_DONE < DONE_LENGTH - 1) ? S_DONE : S_IDLE;
            default: next_state <= S_IDLE;
        endcase
    
    // combinational logic for bram_addr
    always @(*) begin
        case (present_state)
            S_LOAD: bram_addr <= (cnt_LOAD_s < BLK_WIDTH) ?
                    cnt_CALC + cnt_LOAD_s * BLK_WIDTH : // first matrix
                    cnt_LOAD_s - BLK_WIDTH + cnt_CALC * 
                    BLK_WIDTH + BLK_WIDTH**2;           // second matrix
            S_TRAN: bram_addr <= cnt_TRAN;
            default: bram_addr <= 0;
        endcase
    end
    
endmodule

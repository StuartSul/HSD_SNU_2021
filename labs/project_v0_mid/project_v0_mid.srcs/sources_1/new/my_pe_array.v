`timescale 1ns / 1ps

module my_pe_array #(
    parameter L_RAM_SIZE = 6, // global buffer size
    parameter BRAM_SIZE = 15, // FPGA memory size
    parameter BLOCK_SIZE = 4 // input matrix size
)(
    input start, // start signal
    input aresetn, // active-low reset signal
    input aclk,   // clock signal
    input [31:0] rddata, // data from memory
    output [BRAM_SIZE-1:0] rdaddr, // memory address to read data from
    output [31:0] wrdata, // output
    output done // done signal
);
    
    wire [BLOCK_SIZE**2-1:0] dvalid; // dvalid signals from PE array
    wire [31:0] dout [0:BLOCK_SIZE**2-1]; // douts from PE array
    reg [31:0] dout_reg [0:BLOCK_SIZE**2-1]; // registers holding douts
    reg ready; // ready signal for next set of inputs
    reg [2:0] present_state, next_state; // state registers
    reg [31:0] gb [0:2**L_RAM_SIZE-1]; // global buffer
    reg [L_RAM_SIZE-1:0] cnt, cnt_MAC; // counters
    
    // states
    localparam S_IDLE = 3'd0, S_LOAD = 3'd1, S_WAIT = 3'd2,
               S_CALC = 3'd3, S_DONE = 3'd4;

    // output assignments
    assign rdaddr = (present_state == S_LOAD) ? cnt + cnt_MAC * BLOCK_SIZE * 2 : 0; // TODO: fix this to fit actual BRAM address
    assign wrdata = (present_state == S_DONE) ? dout_reg[cnt] : 0; // TODO: fix this to fit actual BRAM address
    assign done = (present_state == S_DONE);
    
    // PE array
    genvar row, col;
    for (row = 0; row < BLOCK_SIZE; row = row + 1) begin:PE_ROW
        for (col = 0; col < BLOCK_SIZE; col = col + 1) begin:PE_COL
            my_pe PE(
                .aclk(aclk),
                .aresetn(aresetn | ~(present_state == S_IDLE || 
                                     present_state == S_DONE)),
                .ain(gb[row]),
                .bin(gb[col + BLOCK_SIZE]),
                .valid(present_state == S_CALC),
                .dvalid(dvalid[row * BLOCK_SIZE + col]),
                .dout(dout[row * BLOCK_SIZE + col])
            );
        end
    end
    
    // counters
    always @(posedge aclk) begin
        cnt <= (present_state == S_LOAD || 
                present_state == S_DONE) ? cnt + 1 : 0;
        cnt_MAC <= (present_state == S_CALC) ? cnt_MAC + 1 : 
                  ((present_state == S_LOAD ||
                    present_state == S_WAIT) ? cnt_MAC : 0);
    end
    
    // wrdata
    for (row = 0; row < BLOCK_SIZE; row = row + 1) begin
        for (col = 0; col < BLOCK_SIZE; col = col + 1) begin
             always @(posedge aclk)
                if (cnt_MAC == BLOCK_SIZE && dvalid)
                    dout_reg[row * BLOCK_SIZE + col] <= dout[row * BLOCK_SIZE + col];
                else if (next_state == S_DONE)
                    dout_reg[row * BLOCK_SIZE + col] <= dout_reg[row * BLOCK_SIZE + col];
                else
                    dout_reg[row * BLOCK_SIZE + col] <= 0;
        end
    end
    
    // global buffer
    always @(posedge aclk)
        gb[cnt] <= (present_state == S_LOAD) ? rddata : gb[cnt];
    
    // present_state
    always @(posedge aclk)
        present_state <= (aresetn) ? next_state : S_IDLE;
    
    // combinational logic for next_state
    always @(*)
        case (present_state)
            S_IDLE: next_state <= (start) ? S_LOAD : S_IDLE;
            S_LOAD: next_state <= (cnt < BLOCK_SIZE * 2 - 1) ? S_LOAD : 
                                  ((cnt_MAC == 0) ? S_CALC : S_WAIT);
            S_WAIT: next_state <= (dvalid) ? ((cnt_MAC == BLOCK_SIZE) ? S_DONE : S_CALC) : S_WAIT;
            S_CALC: next_state <= (cnt_MAC == BLOCK_SIZE - 1) ? S_WAIT : S_LOAD;
            S_DONE: next_state <= (cnt == BLOCK_SIZE**2-1) ? S_IDLE : S_DONE;
        endcase
    
endmodule

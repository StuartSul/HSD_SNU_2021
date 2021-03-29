`timescale 1ns / 1ps

module my_pe_array #(
    parameter L_RAM_SIZE = 6,
    parameter BRAM_SIZE = 15,
    parameter BLOCK_SIZE = 16
)(
    input start,
    input aresetn,
    input aclk,
    input [31:0] rddata,
    output [BRAM_SIZE-1:0] rdaddr,
    output [31:0] wrdata,
    output done
);
    
    wire [BLOCK_SIZE**2-1:0] dvalid;
    wire [31:0] dout [0:BLOCK_SIZE**2-1];
    reg [31:0] wrdata_reg [0:BLOCK_SIZE**2-1];
    reg valid;
    reg [1:0] present_state, next_state;
    reg [31:0] gb [0:BLOCK_SIZE*2-1]; // global buffer
    reg [L_RAM_SIZE-1:0] cnt, cnt_MAC; // counters
    
    // states
    localparam S_IDLE = 2'd0, S_LOAD = 2'd1,
               S_CALC = 2'd2, S_DONE = 2'd3;
    
    // output assignment
    assign rdaddr = (present_state == S_LOAD) ? cnt + cnt_MAC * BLOCK_SIZE * 2 : 0; // TODO: fix this to fit actual BRAM address
    assign wrdata = (present_state == S_DONE) ? wrdata_reg[cnt] : 0; // TODO: fix this to fit actual BRAM address
    assign done = present_state == S_DONE;
    
    // PE array
    genvar row, col;
    for (row = 0; row < BLOCK_SIZE; row = row + 1) begin:PE_ROW
        for (col = 0; col < BLOCK_SIZE; col = col + 1) begin:PE_COL
            my_pe PE(
                .aclk(aclk),
                .aresetn(aresetn),
                .ain(gb[row]),
                .bin(gb[col + BLOCK_SIZE]),
                .valid(valid),
                .dvalid(dvalid[row * BLOCK_SIZE + col]),
                .dout(dout[row * BLOCK_SIZE + col])
            );
        end
    end
    
    // counters
    always @(posedge aclk) begin
        cnt <= (present_state[0]) ? cnt + 1 : 0; // S_LOAD or S_DONE
        cnt_MAC <= (present_state[0] + present_state[1] == 1) ? cnt_MAC + |dvalid : 0; // S_LOAD or S_CALC
    end
    
    // valid signal
    always @(posedge aclk)
        valid <= (next_state == S_CALC && present_state == S_LOAD) ? 1 : 0;
     
     // wrdata
    for (row = 0; row < BLOCK_SIZE; row = row + 1) begin
        for (col = 0; col < BLOCK_SIZE; col = col + 1) begin
             always @(posedge aclk)
                if (cnt_MAC == BLOCK_SIZE - 1 && dvalid)
                    wrdata_reg[row * BLOCK_SIZE + col] <= dout[row * BLOCK_SIZE + col];
                else if (next_state == S_DONE)
                    wrdata_reg[row * BLOCK_SIZE + col] <= wrdata_reg[row * BLOCK_SIZE + col];
                else
                    wrdata_reg[row * BLOCK_SIZE + col] <= 0;
        end
    end
    
    // global buffer
    always @(posedge aclk)
        gb[cnt] <= (present_state == S_LOAD) ? rddata : gb[cnt];
    
    // present_state
    always @(posedge aclk)
        present_state <= (aresetn) ? next_state : S_IDLE;
    
    // combinational logic for determining next_state
    always @(*)
        case (present_state)
            S_IDLE: next_state <= (start) ? S_LOAD : S_IDLE;
            S_LOAD: next_state <= (cnt == BLOCK_SIZE * 2 - 1) ? S_CALC : S_LOAD;
            S_CALC: next_state <= (dvalid) ? ((cnt_MAC == BLOCK_SIZE - 1) ? S_DONE : S_LOAD) : S_CALC;
            S_DONE: next_state <= (cnt == BLOCK_SIZE**2-1) ? S_IDLE : S_DONE;
        endcase
    
endmodule

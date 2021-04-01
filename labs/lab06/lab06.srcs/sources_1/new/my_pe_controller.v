`timescale 1ns / 1ps

module my_pe_controller #(
    parameter L_RAM_SIZE = 6, // global buffer size
    parameter MEM_SIZE = 5 // external memory size
)(
    input start, // start signal
    input reset, // active-high reset signal
    input clk,   // clock signal
    input [31:0] rddata, // data from memory
    output [MEM_SIZE-1:0] rdaddr, // memory address to read data from
    output reg [31:0] out, // inner product
    output done // done signal
);
    
    wire dvalid; // dvalid from PE
    wire [31:0] dout; // dout from PE
    reg valid; // valid signal input to PE
    reg [1:0] present_state, next_state; // state registers
    reg [31:0] gb [0:2**L_RAM_SIZE-1]; // global buffer
    reg [L_RAM_SIZE-1:0] cnt, cnt_MAC; // counters
    
    // states
    localparam S_IDLE = 2'd0, S_LOAD = 2'd1,
               S_CALC = 2'd2, S_DONE = 2'd3;
    
    // output assignmentsss
    assign rdaddr = cnt;
    assign done = (present_state == S_DONE);
    
    // processing element
    my_pe PE(
        .aclk(clk),
        .aresetn(~(reset | (present_state == S_IDLE || 
                            present_state == S_DONE))),
        .ain(gb[cnt_MAC]),
        .bin(gb[cnt_MAC + 16]),
        .valid(valid),
        .dvalid(dvalid),
        .dout(dout)
    );
    
    // counters
    always @(posedge clk) begin
        cnt <= (present_state[0]) ? cnt + 1 : 0; // S_LOAD or S_DONE
        cnt_MAC <= (present_state == S_CALC) ? cnt_MAC + dvalid : 0;
    end
    
    // valid signal
    always @(posedge clk)
        if (cnt_MAC == 15)
            valid <= 0;
        else if (present_state == S_CALC)
            valid <= dvalid;
        else if (next_state == S_CALC)
            valid <= 1;
        else
            valid <= 0;
     
     // output
     always @(posedge clk)
        if (cnt_MAC == 15 && dvalid)
            out <= dout;
        else if (next_state == S_DONE)
            out <= out;
        else
            out <= 0;
    
    // global buffer
    always @(posedge clk)
        gb[cnt] <= (present_state == S_LOAD) ? rddata : gb[cnt];
    
    // present_state
    always @(posedge clk)
        present_state <= (reset) ? S_IDLE : next_state;
    
    // combinational logic for next_state
    always @(*)
        case (present_state)
            S_IDLE: next_state <= (start) ? S_LOAD : S_IDLE;
            S_LOAD: next_state <= (cnt == 31) ? S_CALC : S_LOAD;
            S_CALC: next_state <= (cnt_MAC == 15 && dvalid) ? S_DONE : S_CALC;
            S_DONE: next_state <= (cnt == 4) ? S_IDLE : S_DONE;
        endcase
        
endmodule

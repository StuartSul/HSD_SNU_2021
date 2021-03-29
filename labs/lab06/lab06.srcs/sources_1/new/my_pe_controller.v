`timescale 1ns / 1ps

module my_pe_controller #(
    parameter L_RAM_SIZE = 6,
    parameter MEM_SIZE = 6
)(
        input start,
        input aresetn,
        input aclk,
        input [31:0] rddata,
        output [MEM_SIZE-1:0] rdaddr,
        output reg [31:0] wrdata,
        output done
    );
    
    wire dvalid;
    wire [31:0] dout;
    reg valid;
    reg [1:0] present_state, next_state;
    reg [31:0] gb [0:31]; // global buffer
    reg [L_RAM_SIZE-1:0] cnt, cnt_MAC; // counters
    
    // states
    localparam S_IDLE = 2'd0, S_LOAD = 2'd1,
               S_CALC = 2'd2, S_DONE = 2'd3;
    
    // output assignment
    assign rdaddr = cnt;
    assign done = present_state == S_DONE;
    
    // processing element
    my_pe PE(
        .aclk(aclk),
        .aresetn(aresetn),
        .ain(gb[cnt_MAC]),
        .bin(gb[cnt_MAC + 16]),
        .valid(valid),
        .dvalid(dvalid),
        .dout(dout)
    );
    
    // counters
    always @(posedge aclk) begin
        cnt <= (present_state[0]) ? cnt + 1 : 0; // S_LOAD or S_DONE
        cnt_MAC <= (present_state == S_CALC) ? cnt_MAC + dvalid : 0;
    end
    
    // valid signal
    always @(posedge aclk)
        if (cnt_MAC == 15)
            valid <= 0;
        else if (present_state == S_CALC)
            valid <= dvalid;
        else if (next_state == S_CALC)
            valid <= 1;
        else
            valid <= 0;
     
     // wrdata
     always @(posedge aclk)
        if (cnt_MAC == 15 && dvalid)
            wrdata <= dout;
        else if (next_state == S_DONE)
            wrdata <= wrdata;
        else
            wrdata <= 0;
    
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
            S_LOAD: next_state <= (cnt == 31) ? S_CALC : S_LOAD;
            S_CALC: next_state <= (cnt_MAC == 15 && dvalid) ? S_DONE : S_CALC;
            S_DONE: next_state <= (cnt == 4) ? S_IDLE : S_DONE;
        endcase
        
endmodule

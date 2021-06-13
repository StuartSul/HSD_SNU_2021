`timescale 1ns / 1ps

module my_pe (
    input aclk, // clk
    input aresetn, // reset (low)
    input [7:0] ain, // port A
    input [7:0] bin, // port B
    input valid, // integrated valid signal
    output dvalid, // computation valig signal
    output [15:0] dout // computation result
);

    reg [15:0] psum; // accumulated result & port C
    reg [15:0] dout_r;
    reg dvalid_r;
    
    wire [15:0] ain_extended;
    wire [15:0] bin_extended;
    wire [31:0] res_extended;
    
    assign dout = dout_r;
    assign dvalid = dvalid_r;
    assign ain_extended = {{8{ain[7]}}, ain};
    assign bin_extended =  {{8{bin[7]}}, bin};
    assign res_extended =  ain_extended * bin_extended + psum;
    
    // accumulator
    always @(posedge aclk) begin
        if (!aresetn)
            psum <= 'd0;
        else if (dvalid) // accumulate
            psum <= dout;
        else
            psum <= psum;
    end
    
    // data valid signal
    always @(posedge aclk) begin
        if (valid && aresetn)
            dvalid_r <= 1;
        else
            dvalid_r <= 0;
    end
    
    // calculation result
    always @(posedge aclk) begin
        if (valid && aresetn)
            dout_r <= res_extended[15:0];
        else
            dout_r <= 0;
    end

endmodule

`timescale 1ns / 1ps

module my_pe (
    input aclk, // clk
    input aresetn, // reset (low)
    input [31:0] ain, // port A
    input [31:0] bin, // port B
    input valid, // integrated valid signal
    output dvalid, // computation valig signal
    output [31:0] dout // computation result
);

    reg [31:0] psum; // accumulated result & port C
    wire [31:0] res; // result from MAC unit
    
    assign dout = dvalid ? res : 32'd0;
    
    always @(posedge aclk) begin
        if (!aresetn)
            psum <= 'd0;
        else if (dvalid) // accumulate
            psum <= res;
        else
            psum <= psum;
    end
    
    floating_point_MAC MAC(
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_a_tvalid(valid),
        .s_axis_b_tvalid(valid),
        .s_axis_c_tvalid(valid),
        .s_axis_a_tdata(ain),
        .s_axis_b_tdata(bin),
        .s_axis_c_tdata(psum),
        .m_axis_result_tvalid(dvalid),
        .m_axis_result_tdata(res)
    );
   
endmodule

`timescale 1ns / 1ps

module my_pe #(
    parameter L_RAM_SIZE = 6
) (
    // clk/reset
    input aclk,
    input aresetn,
    
    // port A
    input [31:0] ain,
    
    // peram -> port B 
    input [31:0] din,
    input [L_RAM_SIZE-1:0] addr,
    input we,
    
    // integrated valid signal
    input valid,
    
    // computation result
    output dvalid,
    output [31:0] dout
);

    (* ram_style = "block" *) reg [31:0] peram [0:2**L_RAM_SIZE - 1]; // local register
    reg [31:0] psum; // accumulated result & port C
    wire [31:0] bin; // port B to MAC
    wire [31:0] res; // result from MAC
    
    assign bin = peram[addr];
    assign dout = dvalid ? res : 0;
    
    always @(posedge aclk) begin
        if (we)
            peram[addr] <= din;
        if (!aresetn)
            psum <= 'd0;
        else if (dvalid)
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

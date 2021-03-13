`timescale 1ns / 1ps

module my_fusedmult#(
    parameter BITWIDTH = 32 
)
(
    input [BITWIDTH-1:0] ain,
    input [BITWIDTH-1:0] bin,
    input en,
    input clk,
    output [2*BITWIDTH-1:0] dout
);

reg [2*BITWIDTH-1:0] dout_reg;

always @(posedge clk)
begin
    dout_reg <= en ? dout_reg + ain * bin : 0;
end

assign dout = dout_reg;

endmodule

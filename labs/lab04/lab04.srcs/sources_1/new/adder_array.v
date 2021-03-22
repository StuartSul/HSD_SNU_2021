`timescale 1ns / 1ps

module adder_array(cmd, 
    ain0, ain1, ain2, ain3, 
    bin0, bin1, bin2, bin3, 
    dout0, dout1, dout2, dout3, 
    overflow);
    
    input [2:0] cmd;
    input [31:0] ain0, ain1, ain2, ain3;
    input [31:0] bin0, bin1, bin2, bin3;
    output [31:0] dout0, dout1, dout2, dout3;
    output [3:0] overflow;
    
    wire [31:0] ain [3:0];
    wire [31:0] bin [3:0];
    wire [31:0] dout [3:0];
    wire [3:0] _overflow;
    
    assign {ain[0], ain[1], ain[2], ain[3]} = {ain0, ain1, ain2, ain3};
    assign {bin[0], bin[1], bin[2], bin[3]} = {bin0, bin1, bin2, bin3};
    
    genvar i;
    generate for (i = 0; i < 4; i = i + 1) begin:adder
        my_add ADDER(.ain(ain[i]), .bin(bin[i]), .dout(dout[i]), .overflow(_overflow[i]));
    end endgenerate
    
    assign {dout0, dout1, dout2, dout3} = {
                cmd == 3'd0 || cmd == 3'd4 ? dout[0] : 0, 
                cmd == 3'd1 || cmd == 3'd4 ? dout[1] : 0, 
                cmd == 3'd2 || cmd == 3'd4 ? dout[2] : 0, 
                cmd == 3'd3 || cmd == 3'd4 ? dout[3] : 0
            };
            
    assign overflow = {
                cmd == 3'd3 || cmd == 3'd4 ? _overflow[3] : 1'b0,
                cmd == 3'd2 || cmd == 3'd4 ? _overflow[2] : 1'b0,
                cmd == 3'd1 || cmd == 3'd4 ? _overflow[1] : 1'b0,
                cmd == 3'd0 || cmd == 3'd4 ? _overflow[0] : 1'b0
            };
    
endmodule

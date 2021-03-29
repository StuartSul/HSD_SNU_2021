`timescale 1ns / 1ps

module tb_pe #(
    parameter L_RAM_SIZE = 6
) ();
    
    reg [31:0] gb1 [0:2**L_RAM_SIZE - 1]; // global buffer 1
    reg [31:0] gb2 [0:2**L_RAM_SIZE - 1]; // global buffer 2
    reg [L_RAM_SIZE - 1:0] addr; // address for global buffers
    reg clk, rst, valid;
    wire dvalid;
    wire [31:0] dout;
    
    my_pe PE(
        .aclk(clk),
        .aresetn(~rst),
        .ain(gb1[addr]),
        .bin(gb2[addr]),
        .valid(valid),
        .dvalid(dvalid),
        .dout(dout)
    );

    initial begin
        addr <= 0; clk <= 0; rst <= 1; valid <= 0;
        
        // global buffer 1 stores 0.0~15.0
        gb1[0] = 32'h00000000; gb1[1] = 32'h3f800000; gb1[2] = 32'h40000000; gb1[3] = 32'h40400000; 
        gb1[4] = 32'h40800000; gb1[5] = 32'h40a00000; gb1[6] = 32'h40c00000; gb1[7] = 32'h40e00000;
        gb1[8] = 32'h41000000; gb1[9] = 32'h41100000; gb1[10] = 32'h41200000; gb1[11] = 32'h41300000;
        gb1[12] = 32'h41400000; gb1[13] = 32'h41500000; gb1[14] = 32'h41600000; gb1[15] = 32'h41700000;
        
        // global buffer 2 stores 1.0~16.0
        gb2[0] = 32'h3f800000; gb2[1] = 32'h40000000; gb2[2] = 32'h40400000; gb2[3] = 32'h40800000; 
        gb2[4] = 32'h40a00000; gb2[5] = 32'h40c00000; gb2[6] = 32'h40e00000; gb2[7] = 32'h41000000; 
        gb2[8] = 32'h41100000; gb2[9] = 32'h41200000; gb2[10] = 32'h41300000; gb2[11] = 32'h41400000; 
        gb2[12] = 32'h41500000; gb2[13] = 32'h41600000; gb2[14] = 32'h41700000; gb2[15] = 32'h41800000;
        
        // start multiply-accumulation
        #20; rst <= 0; #10;
        repeat(16) begin
            valid <= 1;
            #10;
            valid <= 0;
            wait(dvalid) #10;
            addr <= addr + 1;
        end
    end
    
    always #5 clk = ~clk;

endmodule

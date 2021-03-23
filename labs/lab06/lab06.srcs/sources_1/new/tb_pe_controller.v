`timescale 1ns / 1ps

module tb_pe_controller();

    reg start, rst, clk;
    reg [31:0] mem [0:31];
    wire [5:0] rdaddr;
    wire [31:0] out;
    wire done;
    
    my_pe_controller PE_CONTROLLER(
        .start(start),
        .reset(rst),
        .clk(clk),
        .rdaddr(rdaddr),
        .rddata(mem[rdaddr]),
        .out(out),
        .done(done)
    );
    
    initial begin
        clk <= 0;
        rst <= 0;
        start <= 1;
        
        // assign values to mem (0.0~15.0 for mem[0]~mem[15] and 1.0~16.0 for mem[16]~mem[31])
        mem[0] = 32'h00000000; mem[1] = 32'h3f800000; mem[2] = 32'h40000000; mem[3] = 32'h40400000; 
        mem[4] = 32'h40800000; mem[5] = 32'h40a00000; mem[6] = 32'h40c00000; mem[7] = 32'h40e00000;
        mem[8] = 32'h41000000; mem[9] = 32'h41100000; mem[10] = 32'h41200000; mem[11] = 32'h41300000;
        mem[12] = 32'h41400000; mem[13] = 32'h41500000; mem[14] = 32'h41600000; mem[15] = 32'h41700000;
        mem[16] = 32'h3f800000; mem[17] = 32'h40000000; mem[18] = 32'h40400000; mem[19] = 32'h40800000; 
        mem[20] = 32'h40a00000; mem[21] = 32'h40c00000; mem[22] = 32'h40e00000; mem[23] = 32'h41000000; 
        mem[24] = 32'h41100000; mem[25] = 32'h41200000; mem[26] = 32'h41300000; mem[27] = 32'h41400000; 
        mem[28] = 32'h41500000; mem[29] = 32'h41600000; mem[30] = 32'h41700000; mem[31] = 32'h41800000;
    end
    
    always #5 clk = ~clk;

endmodule

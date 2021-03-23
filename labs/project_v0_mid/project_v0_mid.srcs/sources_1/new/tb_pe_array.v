`timescale 1ns / 1ps

module tb_pe_array();
    
    localparam INIT_FILE = "input.txt";

    reg start, rst, clk;
    reg [31:0] mem [0:64*64*2-1];
    wire [12:0] rdaddr;
    wire [31:0] wrdata;
    wire done;
    
    my_pe_array PE_ARRAY(
        .start(start),
        .reset(rst),
        .clk(clk),
        .rdaddr(rdaddr),
        .rddata(mem[rdaddr]),
        .wrdata(wrdata),
        .done(done)
    );
    
    initial begin
        clk <= 0;
        rst <= 0;
        start <= 1;
        $readmemh(INIT_FILE, mem);
    end
    
    always #5 clk = ~clk;

endmodule

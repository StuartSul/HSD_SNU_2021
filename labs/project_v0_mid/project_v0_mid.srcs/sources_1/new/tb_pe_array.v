`timescale 1ns / 1ps

module tb_pe_array();
    
//    localparam INIT_FILE = "input.txt";

    reg start, rst, clk;
    reg [31:0] mem [0:16*16*2-1];
    wire [14:0] rdaddr;
    wire [31:0] wrdata;
    wire done;
    
    my_pe_array PE_ARRAY(
        .start(start),
        .aresetn(~rst),
        .aclk(clk),
        .rddata(mem[rdaddr]),
        .rdaddr(rdaddr),
        .wrdata(wrdata),
        .done(done)
    );
    
//    genvar i, j;
//    for (i = 0; i < 4; i = i + 1) begin
//        for (j = 0; j < 4; j = j + 1) begin
//            initial begin
//                mem[i * 4 + j] <= 32'h3f800000;
//                mem[16 + i * 4 + j] <= 32'h3f800000;
//            end
//        end
//    end
    initial begin
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
    /*
    
       0 8 1  9     4  5  6  7    218 236 254 272
      1  9 2 10    12 13 14 15    252 274 296 318
      2 10 3 11     5  6  7  8    286 312 338 364
      3 11 4 12    13 14 15 16    320 350 380 410
    
    */
    
    
    
    initial begin
        clk <= 0;
        rst <= 1; #20; rst <= 0;
        start <= 1;
//        $readmemh(INIT_FILE, mem);
    end
    
    always #5 clk = ~clk;

endmodule

`timescale 1ns / 1ps

module tb_bram();
    reg clk, rst, en, done;
    reg [15-1:0] BRAM1_ADDR;
    reg [15-1:0] BRAM2_ADDR;
    reg [3:0] BRAM2_WE;
    wire [31:0] BRAM1_RDDATA;
    wire [31:0] BRAM2_RDDATA; // unused

    my_bram #(
        .OUT_FILE("")
    ) BRAM1(
        .BRAM_ADDR(BRAM1_ADDR),
        .BRAM_CLK(clk),
        .BRAM_WRDATA(32'd0),
        .BRAM_RDDATA(BRAM1_RDDATA),
        .BRAM_EN(en),
        .BRAM_RST(rst),
        .BRAM_WE(4'd0),
        .done(done)
    );
    
    my_bram #(
        .INIT_FILE("")
    ) BRAM2(
        .BRAM_ADDR(BRAM2_ADDR),
        .BRAM_CLK(clk),
        .BRAM_WRDATA(BRAM1_RDDATA),
        .BRAM_RDDATA(BRAM2_RDDATA),
        .BRAM_EN(en),
        .BRAM_RST(rst),
        .BRAM_WE(BRAM2_WE),
        .done(done)
    );
    
    initial begin // BRAM 1
        clk <= 0; rst <= 0; en <= 1; done <= 0;
        BRAM1_ADDR <= 14'd0;
        repeat(8192-1) begin
            #10;
            BRAM1_ADDR <= BRAM1_ADDR + 15'b100;
        end
    end
    
    initial begin // BRAM 2
        BRAM2_ADDR <= 14'd0;
        BRAM2_WE <= 4'd0;
        #20
        BRAM2_WE <= 4'hf;
        repeat(8192-1) begin
            #10;
            BRAM2_ADDR <= BRAM2_ADDR + 15'b100;
        end
        #10; done <= 1; #5; $finish;
    end
    
    always #5 clk = ~clk;

endmodule

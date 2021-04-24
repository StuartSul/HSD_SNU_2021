`timescale 1ns / 1ps

module tb_pe_array();

    reg start;
    wire done;
    reg S_AXI_ARESETN;
    reg S_AXI_ACLK;
    wire [31:0] BRAM_ADDR;
    wire [31:0] BRAM_RDDATA;
    wire [31:0] BRAM_WRDATA;
    wire [3:0] BRAM_WE;
    wire BRAM_CLK;
    
    my_pe_array PE_ARRAY(
        .start(start),
        .done(done),
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .BRAM_ADDR(BRAM_ADDR),
        .BRAM_RDDATA(BRAM_RDDATA),
        .BRAM_WRDATA(BRAM_WRDATA),
        .BRAM_WE(BRAM_WE),
        .BRAM_CLK(BRAM_CLK)
    );
    
    my_bram #(
        .BRAM_ADDR_WIDTH(32)
    ) BRAM (
        .BRAM_ADDR(BRAM_ADDR),
        .BRAM_CLK(BRAM_CLK),
        .BRAM_WRDATA(BRAM_WRDATA),
        .BRAM_RDDATA(BRAM_RDDATA),
        .BRAM_EN(1'b1),
        .BRAM_RST(~S_AXI_ARESETN),
        .BRAM_WE(BRAM_WE),
        .done(done)
    );
    
    initial begin
        S_AXI_ACLK <= 0;
        S_AXI_ARESETN <= 0; 
        #20; 
        S_AXI_ARESETN <= 1;
        start <= 1;
    end
    
    always #5 S_AXI_ACLK = ~S_AXI_ACLK;

endmodule

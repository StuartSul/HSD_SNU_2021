`timescale 1ns / 1ps

module tb_pe();
    
     reg clk, rst, we, valid;
     reg [31:0] ain;
     reg [31:0] din;
     reg [6-1:0] addr;
     wire dvalid;
     wire [31:0] dout;
    
    my_pe PE(
        .aclk(clk),
        .aresetn(~rst),
        .ain(ain),
        .din(din),
        .addr(addr),
        .we(we),
        .valid(valid),
        .dvalid(dvalid),
        .dout(dout)
    );
    
    // assign float values 0.0~15.0 to dins
    wire [31:0] dins [0:15];
    wire [32*16-1:0] values;
    assign values = {32'h00000000, 32'h3f800000, 32'h40000000, 32'h40400000, 
                     32'h40800000, 32'h40a00000, 32'h40c00000, 32'h40e00000, 
                     32'h41000000, 32'h41100000, 32'h41200000, 32'h41300000, 
                     32'h41400000, 32'h41500000, 32'h41600000, 32'h41700000};
    genvar idx;
    for (idx = 0; idx < 16; idx = idx + 1) begin
        assign dins[idx] = values[32*(16-idx)-1:32*(15-idx)];
    end

    integer i;
    initial begin
        clk <= 0;
        rst <= 0;
        valid <= 0;
        we <= 1;
        
        // assign float values 0.0~15.0 to local buffer in PE
        for (i = 0; i < 16; i = i + 1) begin
            din <= dins[i];
            addr <= i;
            #10;
        end
        
        // start multiply-accumulation
        we <= 0; 
        for (i = 0; i < 16; i = i + 1) begin
            valid <= 1;
            ain <= 32'h40000000;
            addr <= i;
            #10;
            valid <= 0;
            wait(dvalid) #10;
        end
    end
    
    always #5 clk = ~clk;

endmodule

`timescale 1ns / 1ps

module my_bram #(
    parameter integer BRAM_ADDR_WIDTH = 15, // 4x8192
    parameter INIT_FILE = "input.txt",
    parameter OUT_FILE = "output.txt"
) (
    input wire [BRAM_ADDR_WIDTH-1:0] BRAM_ADDR,
    input wire BRAM_CLK,
    input wire [31:0] BRAM_WRDATA,
    output reg [31:0] BRAM_RDDATA,
    input wire BRAM_EN,
    input wire BRAM_RST,
    input wire [3:0] BRAM_WE,
    input wire done
);
    
    reg [31:0] mem [0:8191];
    wire [BRAM_ADDR_WIDTH-3:0] addr = BRAM_ADDR[BRAM_ADDR_WIDTH-1:2];
    reg [31:0] dout;

    // code for initial read & final write
    initial begin
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
        wait(done)
            if (OUT_FILE != "")
                $writememh(OUT_FILE, mem);
    end
    
    // code for BRAM functioning
    always @(posedge BRAM_CLK) begin
        if (BRAM_EN) begin
            if (BRAM_WE[0])
                mem[addr][7:0] <= BRAM_WRDATA[7:0];
            if (BRAM_WE[1])
                mem[addr][15:8] <= BRAM_WRDATA[15:8];
            if (BRAM_WE[2])
                mem[addr][23:16] <= BRAM_WRDATA[23:16];
            if (BRAM_WE[3])
                mem[addr][31:24] <= BRAM_WRDATA[31:24];
            if (!BRAM_WE)
                dout <= mem[addr];
        end
        if (BRAM_RST)
            BRAM_RDDATA <= 32'd0;
        else if (BRAM_EN)
            BRAM_RDDATA <= dout;
    end
    
endmodule

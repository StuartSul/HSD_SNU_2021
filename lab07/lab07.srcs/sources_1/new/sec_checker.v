`timescale 1ns / 1ps

module sec_checker(
    input GCLK,
    input CENTER_PUSHBUTTON,
    output [7:0] LED
);
    
    localparam CLK_FREQ = 32'd100000000; 

    reg [31:0] down_counter;
    reg [7:0] up_counter;
    
    assign LED = up_counter;
    
    always @(posedge GCLK) begin
        if (CENTER_PUSHBUTTON) begin
            down_counter <= CLK_FREQ - 1;
            up_counter <= 8'd0;
        end else if (down_counter == 31'd0) begin
            down_counter <= CLK_FREQ - 1;
            up_counter <= up_counter + 8'd1;
        end else begin
            down_counter <= down_counter - 31'd1;
        end
    end

endmodule

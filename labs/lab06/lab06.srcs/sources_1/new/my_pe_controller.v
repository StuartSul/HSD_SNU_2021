`timescale 1ns / 1ps

module my_pe_controller #(
    parameter L_RAM_SIZE = 6,
    parameter MEM_SIZE = 6
)(
        input start,
        input reset,
        input clk,
        output [MEM_SIZE-1:0] rdaddr,
        input [31:0] rddata,
        output [31:0] out,
        output done
    );
    
    localparam S_IDLE = 2'd0;
    localparam S_LOAD = 2'd1;
    localparam S_CALC = 2'd2;
    localparam S_DONE = 2'd3;
    
    wire dvalid;
    wire [31:0] dout;
    reg we = 0;
    reg valid = 0;
    reg [31:0] out_reg = 0;
    reg done_reg = 0;
    reg [1:0] state = S_IDLE;
    reg [31:0] global_buffer [0:15];
    reg [L_RAM_SIZE-1:0] counter = 'd0;
    
    my_pe PE(
        .aclk(clk),
        .aresetn(~reset),
        .ain(global_buffer[counter]),
        .din(rddata),
        .addr(counter),
        .we(we),
        .valid(valid),
        .dvalid(dvalid),
        .dout(dout)
    );
    
    defparam PE.L_RAM_SIZE = L_RAM_SIZE;

    assign rdaddr = counter;
    assign out = out_reg;
    assign done = done_reg;

    // FSM
    always @(posedge clk) begin
        case (state)
        
            S_IDLE:
                begin
                    if (start) begin
                        state <= S_LOAD;
                        counter <= 'd0;
                        we <= 1'b1;
                    end else begin
                        state <= S_IDLE;
                    end
                end
                
            S_LOAD:
                begin
                    if (counter < 'd15) begin
                        counter <= counter + 'd1;
                    end else if (counter == 'd15) begin
                        we <= 1'b0;
                        counter <= counter + 'd1;
                    end else if (counter < 'd31) begin
                        global_buffer[counter - 'd16] <= rddata;
                        counter <= counter + 'd1;
                    end else begin
                        state <= S_CALC;
                        global_buffer[counter - 'd16] <= rddata;
                        counter <= 'd0;
                        valid <= 1'b1;
                    end
                end
                
            S_CALC:
                begin
                    if (valid) begin
                        valid <= 1'b0;
                    end else if (dvalid) begin
                        if (counter < 'd15) begin
                            counter <= counter + 'd1;
                            valid <= 1'b1;
                        end else begin
                            state <= S_DONE;
                            counter <= 'd0;
                            valid <= 1'b0;
                            out_reg <= dout;
                            done_reg <= 1'b1;
                        end
                    end else begin
                        counter <= counter;
                        valid <= valid;
                    end
                end
                
            S_DONE:
                begin
                    if (counter < 'd4) begin
                        counter <= counter + 'd1;
                    end else begin
                        state <= S_IDLE;
                        out_reg <= 'd0;
                        counter <= 'd0;
                        done_reg <= 1'b0;
                    end
                end
                
            default:
                state <= S_IDLE;
        endcase
    end
    
endmodule

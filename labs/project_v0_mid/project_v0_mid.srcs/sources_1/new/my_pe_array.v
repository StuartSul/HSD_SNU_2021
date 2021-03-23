`timescale 1ns / 1ps

module my_pe_array #(
    parameter L_RAM_SIZE = 6,
    parameter MEM_SIZE = 13,
    parameter DONE_DELAY = 5
)(
    input wire start,
    input wire reset,
    input wire clk,
    output wire [MEM_SIZE-1:0] rdaddr,
    input wire [31:0] rddata,
    output wire [31:0] wrdata,
    output reg done = 1'b0
);
    
    localparam S_IDLE = 3'd0;
    localparam S_PELD = 3'd1;
    localparam S_GBLD = 3'd2;
    localparam S_CALC = 3'd3;
    localparam S_MOVE = 3'd4;
    localparam S_DONE = 3'd5;
    
    localparam BLOCK_LENGTH = 2**L_RAM_SIZE;
    
    wire dvalid [0:BLOCK_LENGTH-1][0:BLOCK_LENGTH-1];
    wire [31:0] dout [0:BLOCK_LENGTH-1][0:BLOCK_LENGTH-1];
    
    reg we [0:BLOCK_LENGTH-1];
    reg valid = 0;
    reg [31:0] dout_reg [0:BLOCK_LENGTH-1][0:BLOCK_LENGTH-1];
    
    reg [2:0] state = S_IDLE;
    reg [31:0] global_buffer [0:BLOCK_LENGTH-1][0:BLOCK_LENGTH-1];
    reg [L_RAM_SIZE-1:0] row_counter = 'd0;
    reg [L_RAM_SIZE-1:0] col_counter = 'd0;
    
    genvar i, j;
    integer k, l;
    for (i = 0; i < BLOCK_LENGTH; i = i + 1) begin:PE_ROW
        for (j = 0; j < BLOCK_LENGTH; j = j + 1) begin:PE_COL
            my_pe PE(
                .aclk(clk),
                .aresetn(~reset),
                .ain(global_buffer[i][col_counter]),
                .din(rddata),
                .addr(row_counter),
                .we(we[j]),
                .valid(valid),
                .dvalid(dvalid[i][j]),
                .dout(dout[i][j])
            );
            defparam PE.L_RAM_SIZE = L_RAM_SIZE;
        end
    end

    assign rdaddr = row_counter * BLOCK_LENGTH + col_counter;
    assign wrdata = (state == S_MOVE) ? dout_reg[row_counter][col_counter] : 'd0;

    // FSM
    always @(posedge clk) begin
        case (state)
        
            S_IDLE:
                begin
                    if (start) begin
                        state <= S_PELD;
                        row_counter <= 'd0;
                        col_counter <= 'd0;
                        we[0] <= 1'b1;
                    end else begin
                        state <= S_IDLE;
                    end
                end
                
            S_PELD:
                begin
                    if (row_counter < BLOCK_LENGTH - 1) begin
                        row_counter <= row_counter + 'd1;
                    end else begin
                        we[col_counter] <= 1'b0;
                        if (col_counter < BLOCK_LENGTH - 1) begin
                            we[col_counter + 1] <= 1'b1;
                            row_counter <= 'd0;
                            col_counter <= col_counter + 'd1;
                        end else begin
                            state <= S_GBLD;
                            row_counter <= 'd0;
                            col_counter <= 'd0;
                        end
                    end
                end
                
            S_GBLD:
                begin
                    if (col_counter < BLOCK_LENGTH - 1) begin
                        global_buffer[row_counter][col_counter] <= rddata;
                        col_counter <= col_counter + 'd1;
                    end else begin
                        global_buffer[row_counter][col_counter] <= rddata;
                        if (row_counter < BLOCK_LENGTH - 1) begin
                            row_counter <= row_counter + 'd1;
                            col_counter <= 'd0;
                        end else begin
                            state <= S_GBLD;
                            row_counter <= 'd0;
                            col_counter <= 'd0;
                            valid <= 1'b1;
                        end
                    end
                end
                
            S_CALC:
                begin
                    if (valid) begin
                        valid <= 1'b0;
                    end else if (dvalid[0][0]) begin
                        if (row_counter < BLOCK_LENGTH) begin
                            row_counter <= row_counter + 'd1;
                            col_counter <= col_counter + 'd1;
                            valid <= 1'b1;
                        end else begin
                            state <= S_MOVE;
                            row_counter <= 'd0;
                            col_counter <= 'd0;
                            valid <= 1'b0;
                            for (k = 0; k < BLOCK_LENGTH; k = k + 1) begin
                                for (l = 0; l < BLOCK_LENGTH; l = l + 1) begin
                                    dout_reg[k][l] <= dout[k][l];
                                end
                            end
                        end
                    end else begin
                        row_counter <= row_counter;
                        col_counter <= col_counter;
                        valid <= valid;
                    end
                end
                
            S_MOVE:
                begin
                    if (col_counter < BLOCK_LENGTH - 1) begin
                        col_counter <= col_counter + 'd1;
                    end else begin
                        if (row_counter < BLOCK_LENGTH - 1) begin
                            row_counter <= row_counter + 'd1;
                            col_counter <= 'd0;
                        end else begin
                            state <= S_DONE;
                            row_counter <= 'd0;
                            col_counter <= 'd0;
                            valid <= 1'b1;
                            done <= 1'b1;
                        end
                    end
                end
                
            S_DONE:
                begin
                    if (row_counter < DONE_DELAY - 1) begin
                        row_counter <= row_counter + 'd1;
                    end else begin
                        state <= S_IDLE;
                        row_counter <= 'd0;
                        done <= 1'b0;
                    end
                end
                
            default:
                state <= S_IDLE;
        endcase
    end
    
endmodule

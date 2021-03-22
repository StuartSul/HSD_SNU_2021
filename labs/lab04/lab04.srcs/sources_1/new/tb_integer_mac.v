`timescale 1ns / 1ps

module tb_integer_mac();

    // for my IP
    reg [32-1:0] ain;
    reg [32-1:0] bin;
    reg [32-1:0] cin;
    wire [64-1:0] res;
    
    // for test
    integer i;
    // random test vector generation
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            ain = $urandom%(2**31);
            bin = $urandom%(2**31);
            cin = $urandom%(2**31);
            #20;
        end
        $finish;
    end
    
    integer_MAC UUT(
        .SUBTRACT(1'b0),
        .A(ain),
        .B(bin),
        .C(cin),
        .P(res)
    );

endmodule

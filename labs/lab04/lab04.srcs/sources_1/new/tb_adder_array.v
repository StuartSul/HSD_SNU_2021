`timescale 1ns / 1ps

module tb_adder_array();

    // for my IP
    reg [2:0] cmd;
    reg [32-1:0] ain [3:0];
    reg [32-1:0] bin [3:0];
    wire [32-1:0] dout [3:0];
    wire [3:0] overflow;
    
    // for test
    integer i;
    // random test vector generation
    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            ain[0] = i == 0 ? 32'hffffffff : $urandom%(2**31); // overflow test
            ain[1] = i == 1 ? 32'hffffffff : $urandom%(2**31); // overflow test
            ain[2] = $urandom%(2**31);
            ain[3] = $urandom%(2**31);
            bin[0] = $urandom%(2**31);
            bin[1] = $urandom%(2**31);
            bin[2] = $urandom%(2**31);
            bin[3] = $urandom%(2**31);
            for (cmd = 3'd0; cmd < 3'd5; cmd = cmd + 3'd1) #20;
        end
        $finish;
    end
    
    adder_array UUT(
        .cmd(cmd),
        .ain0(ain[0]),
        .ain1(ain[1]),
        .ain2(ain[2]),
        .ain3(ain[3]),
        .bin0(bin[0]),
        .bin1(bin[1]),
        .bin2(bin[2]),
        .bin3(bin[3]),
        .dout0(dout[0]),
        .dout1(dout[1]),
        .dout2(dout[2]),
        .dout3(dout[3]),
        .overflow(overflow)
    );

endmodule

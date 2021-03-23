`timescale 1ns / 1ps

module temp_pe #(
    parameter L_RAM_SIZE = 6
) ();
//    // clk/reset
//    reg aclk;
//    reg aresetn;
    
//    // port A
//    reg [31:0] ain;
    
//    // peram -> port B 
//    reg [31:0] din;
//    reg [L_RAM_SIZE-1:0] addr;
//    reg we;
    
//    // integrated valid signal
//    reg valid;
    
//    // computation result
//    wire dvalid;
//    wire [31:0] dout;

    
    
    
    
    
//    integer i;
//    initial begin
//        aclk <= 0;
//        aresetn <= 1;
//        valid <= 0;
//        we <= 1;
//        addr = 0;
//        din <= 'h40400000;
//        #10;
//        we <= 0;
//        valid <= 1;
//        ain <= 'h40000000;
//        #10;
//        valid <= 0;
//        #100;
//        valid <= 1;
//        #10;
//        valid <= 0;
        
//    end
    
//    always #5 aclk = ~aclk;













//    (* ram_style = "block" *) reg [31:0] peram [0:2**L_RAM_SIZE - 1]; // local register
//    reg [31:0] psum; // accumulated result & port C
//    reg [31:0] bin; // port B
//    wire [31:0] res; // result port from MAC
    
//    assign dout = psum;
    
//    always @(posedge aclk) begin
//        if (we)
//            peram[addr] <= din;
//        else
//            bin <= peram[addr];
    
//        if (aresetn) begin
//            if (dvalid) begin
//                psum <= res;
//            end else begin
//                psum <= psum;
//            end
//        end else begin
//            psum <= 'd0;
//        end
//    end

    reg aclk, valid;
    reg aresetn;
    reg [31:0] ain;
    reg [31:0] bin;
    reg [31:0] psum;
    wire dvalid;
    wire [31:0] res;
    
    initial begin 
        aclk <= 0;
        valid <= 0;
        aresetn <= 1;
        ain <= 'h40000000;
        bin <= 'h40400000;
        psum <= 'd0;
        
        #10;      
        valid <= 1;
        #10
        valid <= 0;
        
//        #200;
//        psum <= res;
    end
    
    always @(posedge aclk) begin
        if (dvalid) 
            psum <= res;
        else
            psum <= psum;
        
    end
    
    always #5 aclk = ~aclk;
    
    floating_point_MAC MAC(
        .aclk(aclk),
        .aresetn(1'b1),
        .s_axis_a_tvalid(valid),
        .s_axis_b_tvalid(valid),
        .s_axis_c_tvalid(valid),
        .s_axis_a_tdata(ain),
        .s_axis_b_tdata(bin),
        .s_axis_c_tdata(psum),
        .m_axis_result_tvalid(dvalid),
        .m_axis_result_tdata(res)
    );
   
endmodule

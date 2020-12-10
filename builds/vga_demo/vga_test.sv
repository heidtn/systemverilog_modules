`include "vga.sv"
`default_nettype none

module vga_test (
    input i_clk,
    output wire D5,
    output wire h_sync,
    output wire v_sync,
    output reg [5:0]pixel
);

wire clk_20mhz;
wire lock;

SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
                  .PLLOUT_SELECT("GENCLK"),
                  .DIVR(4'b0001),
                  .DIVF(7'b1000010),
                  .DIVQ(3'b100),
                  .FILTER_RANGE(3'b001),
                 ) uut (
                         .REFERENCECLK(i_clk),
                         .PLLOUTCORE(clk_20mhz),
                         .LOCK(lock),
                         .RESETB(1'b1),
                         .BYPASS(1'b0)
                        );

wire [9:0]hp;
wire [9:0]vp;
wire display;
vga_sync vga(.i_clk(clk_20mhz), .h_sync(h_sync), .v_sync(v_sync), .hp(hp), .vp(vp), .display(display));

always @(posedge clk_20mhz) begin
    if(display) begin
        pixel <= 6'b110011;
    end else begin
        pixel <= 0;
    end
    //if(display) begin
    //    if(hp > 480) begin
    //        pixel <= 6'b111111;
    //    end else if(hp > 320) begin
    //        pixel <= 6'b110000;
    //    end else if(hp > 160) begin
    //        pixel <= 6'b001100; 
    //    end else begin
    //        pixel <= 6'b000011;
    //    end
    //end else begin
    //    pixel <= 0;
    //end 
end

endmodule
`include "vga.sv"
`include "blockmem.sv"
`include "raycast_buffer.sv"
`default_nettype none

module buffer_test (
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

reg wen1;
reg ren1;
reg [9:0]waddr1;
reg [9:0]raddr1;
reg [9:0]wdata1;
reg [9:0]rdata1;
blockmem bm1(
        .clk(clk_20mhz), .wen(wen1), .ren(ren1), 
        .waddr(waddr1), .raddr(raddr1),
        .wdata(wdata1),
        .rdata(rdata1)
);

reg wen2;
reg ren2;
reg [9:0]waddr2;
reg [9:0]raddr2;
reg [9:0]wdata2;
reg [9:0]rdata2;
blockmem bm2(
        .clk(clk_20mhz), .wen(wen2), .ren(ren2), 
        .waddr(waddr2), .raddr(raddr2),
        .wdata(wdata2),
        .rdata(rdata2)
);

reg buffer_sel;
initial begin
    buffer_sel = 1;
end

raycast_buffer buffer(
    .i_clk(clk_20mhz),
    .buffer1(rdata1),
    .buffer2(rdata2),
    .addr1(raddr1),
    .addr2(raddr2),
    .buffer_sel(buffer_sel),
    .x(hp),
    .y(vp),
    .pixel(pixel));

always @(posedge clk_20mhz) begin
    waddr1 <= 200;
    wdata1 <= 64;
end

endmodule
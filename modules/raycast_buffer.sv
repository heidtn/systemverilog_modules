`default_nettype none

/*
 *
 * TODO:
 * - this misses the first vertical pixel, what's the best way to handle this?  Start at y=-1?
 */

module raycast_buffer(
    input i_clk,
    input [9:0]buffer1,
    input [9:0]buffer2,
    input [9:0]addr1,
    input [9:0]addr2,
    input buffer_sel,
    input [9:0]x,
    input [9:0]y,
    output [5:0]pixel
);

wire [9:0]working_buf;
wire [9:0]working_addr;
assign working_buf = buffer_sel ? buffer1 : buffer2;
assign working_addr = buffer_sel ? addr1 : addr2;

always @(posedge i_clk) begin
    working_addr <= x;
    if(working_buf != 0) begin
        if(y > ((working_buf>>2) + 240) || y < (240 - (working_buf >> 2))) begin
            pixel <= 0;
        end else begin
            pixel <= 6'b111111;
        end
    end else begin
        pixel <= 0;
    end
end

endmodule
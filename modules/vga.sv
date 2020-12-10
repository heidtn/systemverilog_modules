/*
 * TODO:
 * - implement a clock scalar probablyz
 */

`default_nettype none

module vga_sync (
    input i_clk,
    output v_sync,
    output h_sync,
    output reg [9:0]hp,
    output reg [9:0]vp,
    output reg display
);

// This module expects a 20MHZ clock

localparam display_width = 640;     // cga std width
localparam display_height = 480;    // vga std height
localparam hpulse = 96;             // hsync pulse length
localparam vpulse = 2; 	            // vsync pulse length
localparam horizontal_bp = 48;
localparam horizontal_fp = 16;
localparam vertical_bp = 33;
localparam vertical_fp = 10;

localparam hpulse_start = display_width + horizontal_fp;
localparam hpulse_end = hpulse_start + hpulse;

localparam vpulse_start = display_height + vertical_fp;
localparam vpulse_end = vpulse_start + vpulse;

localparam hmax = display_width + horizontal_fp + hpulse + horizontal_bp; // horizontal pixels per line
localparam vmax = display_height + vertical_fp + vpulse + vertical_bp; // vertical lines per frame

initial begin
    hp = 0;
    vp = 0;
    v_sync = 1;
    h_sync = 1;
end

always @(posedge i_clk) begin
    if(hp == hmax) begin
        if(vp == vmax) begin
            vp <= 0;
        end else begin
            vp <= vp + 1;
        end
        hp <= 0;
    end else begin
        hp <= hp + 1;
    end

    if(hp < display_width && vp < display_height) begin
        display <= 1;
    end else begin
        display <= 0;
    end
end

always @(posedge i_clk) begin
    if(hp > hpulse_start && hp < hpulse_end) begin
        h_sync <= 0;
    end else begin
        h_sync <= 1;
    end

    if(vp > vpulse_start && vp < vpulse_end) begin
        v_sync <= 0;
    end else begin
        v_sync <= 1;
    end
end

endmodule
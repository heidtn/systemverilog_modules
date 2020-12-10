`default_nettype none

// Technically lattice has blockram IP, but this does it implicitly and is nicer to deal with

module blockmem #(
    parameter BITS=10,
    parameter WIDTH=640
) (
        input clk, wen, ren, 
        input [$clog2(WIDTH):0] waddr, raddr,
        input [BITS-1:0] wdata,
        output reg [BITS-1:0] rdata
);
        reg [BITS-1:0] mem [WIDTH];
        always @(posedge clk) begin
                if (wen)
                        mem[waddr] <= wdata;
                if (ren)
                        rdata <= mem[raddr];
        end
endmodule

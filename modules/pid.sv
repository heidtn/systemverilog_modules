
module PID #(
    parameter signed kP = 'h100,       // time agnostic kP
    parameter kD_t = 'h800,       // time agnostic kD
    parameter kI_t = 'h0,       // time agnostic kI
    parameter WIDTH = 16,
    parameter QBITS = 8,
    parameter DT='h100          // fixed point DT
) (
    input wire i_clk,
    input logic signed [WIDTH-1:0]i_setpoint,
    input logic signed [WIDTH-1:0]i_curpoint,
    output logic signed [WIDTH-1:0]o_out
);
    // TODO(heidt) add I clipping term
    // TODO(heidt) add optional derivative smoothing term
    // TODO(heidt) keep these errors from overflowing
    logic signed [WIDTH-1:0]error;
    logic signed [WIDTH-1:0]prev_error;
    logic signed [WIDTH-1:0]deriv;
    logic signed [WIDTH-1:0]integral;

    localparam signed kI = (kI_t * DT) >> QBITS;
    localparam signed kD = (kD_t << QBITS) / DT;

    initial begin
        integral = 0;
        deriv = 0;
        prev_error = 0;
    end

    always @(*) begin
        error = i_setpoint - i_curpoint;
        deriv = (error - prev_error);
        o_out = (error*kP >>> QBITS) + (deriv*kD >>> QBITS) + (integral*kI >> QBITS); 
    end

    always @(posedge i_clk) begin
        prev_error <= error;
        integral <= integral + error;
    end

endmodule
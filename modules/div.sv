`default_nettype none

module div #(
    parameter WIDTH=16,
    parameter QBITS=8
) (
    input i_clk,
    input wire signed [WIDTH-1:0]i_num,
    input wire signed [WIDTH-1:0]i_denom,
    input logic i_start,
    output logic [WIDTH-1:0]o_result,
    output logic done,
    output logic o_valid
);
    // TODO(heidt) this approach can overflow, should probably extend the working accumulator
    // and quotient to prevent this
    logic [WIDTH-1:0]denom;
    logic [WIDTH-1:0]num;
    logic [WIDTH-1:0]quotient;
    logic [WIDTH-1:0]accum;
    logic [WIDTH-1:0]quotient_next;
    logic [WIDTH-1:0]accum_next;
    logic is_positive;
    
    logic [WIDTH-1:0]dividend;
    logic [WIDTH-1:0]i;

    initial begin
        done = 1;
        quotient = 0;
        dividend = 0;
        o_valid = 0;
        i = 0;
        is_positive = 1;
    end


    always @(*) begin
        if(accum >= denom) begin
            accum_next = accum - denom;
            {accum_next, quotient_next} = {accum_next[WIDTH-2:0], quotient, 1'b1}; 
        end else begin
            {accum_next, quotient_next} = {accum, quotient} << 1;
        end
    end

    always @(posedge i_clk) begin
        if(i_start && done) begin
            o_valid <= 0;
            o_result <= 0;
            i <= 0;
            denom <= 0;
            if(i_denom == 0) begin
                done <= 1;
            end else begin
                // Convert to positive numbers if negative
                if(i_num[WIDTH-1]) begin
                    num <= (~i_num + 1'b1);
                    {accum, quotient} <= {{WIDTH-1{1'b0}}, (~i_num + 1'b1), 1'b0};
                end else begin
                    num <= i_num;
                    {accum, quotient} <= {{WIDTH-1{1'b0}}, i_num, 1'b0};
                end

                if(i_denom[WIDTH-1]) begin
                    denom <= (~i_denom + 1'b1);
                end else begin
                    denom <= i_denom;
                end

                // At the end we need to flip the sign if the result should be negative 
                if(i_num[WIDTH-1] ^ i_denom[WIDTH-1]) begin
                    is_positive <= 0;
                end else begin
                    is_positive <= 1;
                end
                done <= 0;
            end
        end else if(!done) begin
            if (i == WIDTH-1) begin
                done <= 1;
                o_valid <= 1;
                if(is_positive) begin
                    o_result <= ((quotient_next << QBITS) | (accum_next >> 2)); // TODO(heidt) why left shift 2? Should only be 1...  
                end else begin
                    o_result <= ~((quotient_next << QBITS) | (accum_next >> 2)) + 1; // TODO(heidt) why left shift 2? Should only be 1...  
                end
            end else begin
                i <= i + 1;
                accum <= accum_next;
                quotient <= quotient_next;
            end     
        end
    end

endmodule
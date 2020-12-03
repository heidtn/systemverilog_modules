`timescale 1ns/1ps

module mat_mul #(parameter BITWIDTH=16, parameter QBITS=8, parameter MAT1ROWS=3,
                 parameter MAT1COLS=3, parameter MAT2COLS=3) (
                 input wire i_clk,
                 input  wire [BITWIDTH-1:0] i_mat1[MAT1ROWS*MAT1COLS],
                 input  wire [BITWIDTH-1:0] i_mat2[MAT1COLS*MAT2COLS],
                 output logic [BITWIDTH-1:0] o_mat[MAT1ROWS*MAT2COLS],
                 output logic o_done);

    logic [BITWIDTH*2-1:0] mat_calc[MAT1ROWS*MAT2COLS];
    initial begin
        for(int i = 0; i < MAT1ROWS*MAT2COLS; i++) begin
            o_mat[i] = '0;
            mat_calc[i] = '0;
        end
    end

    // TODO(heidt) this seems very sequential and bad, fix maybe?
    always @(*) begin
        logic [(BITWIDTH*2):0] element;
        o_done = '0;
        
        for(int i = 0; i < MAT1ROWS; i = i + 1) begin
            for(int j = 0; j < MAT2COLS; j = j + 1) begin
                element = 0;
                for(int k = 0; k < MAT1COLS; k = k + 1) begin
                    element += ((i_mat1[i*MAT1COLS + k] * i_mat2[k*MAT2COLS + j]) >> QBITS);
                end
                mat_calc[i*MAT2COLS + j] = element;
            end
        end
        o_done = 1;
    end

    always @(posedge i_clk) begin
        for(int i = 0; i < MAT1ROWS*MAT2COLS; i++) begin
            o_mat[i] <= mat_calc[i];
        end
    end
endmodule
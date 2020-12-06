`include "div.sv"
`default_nettype none

module mat_inv #(
    parameter ORDER=3,
    parameter WIDTH=16,
    parameter QBITS=8
) (
    input wire i_clk,
    input wire i_start,
    input wire [WIDTH-1:0]i_mat[ORDER*ORDER],
    output logic [WIDTH-1:0]o_mat[ORDER*ORDER],
    output logic o_done
);
    // TODO(heidt) check for singular matrices in 0 divide
    // TODO(heidt) quick hack to not lose bits by doubling bitsize of o_mat, find a way to multiply and shift without losing bits

    typedef enum {IDLE, IDENTITY, INTERCHANGE, DIAGONALIZE, INVERT} state_t;
    typedef enum {LOAD, DELAY, DIVIDE, READY} divider_substate_t;
    state_t state;
    divider_substate_t divider_state;
    logic [WIDTH-1:0]mat[ORDER*ORDER];
    logic [ORDER:0] row;
    logic [ORDER:0] col;

    logic [WIDTH-1:0] div_num;
    logic [WIDTH-1:0] div_denom;
    logic [WIDTH-1:0] div_result;
    logic div_start;
    logic div_done;
    logic div_valid;
    div #(.WIDTH(WIDTH), .QBITS(QBITS)) div1(.i_clk(i_clk), .i_num(div_num), .i_denom(div_denom),
                                             .i_start(div_start), .o_result(div_result), .done(div_done), .o_valid(div_valid));

    initial begin
        o_done = 0; 
        state = IDLE;
        divider_state = LOAD;
        for(int i = 0; i < ORDER; i += 1) begin
            for(int j = 0; j < ORDER; j += 1) begin
                o_mat[i*ORDER + j] = 0;
            end
        end
    end

    always @(*) begin
        
    end

    always @(posedge i_clk) begin
        case (state)
            IDLE: begin
                if(i_start) begin
                    state <= IDENTITY;
                    for(int i = 0; i < ORDER; i++) begin
                        for(int j = 0; j < ORDER; j++) begin
                            mat[i*ORDER + j] <= i_mat[i*ORDER + j];
                        end
                    end
                end else begin
                    state <= IDLE;
                end
            end 
            IDENTITY: begin
                for(int i = 0; i < ORDER; i+=1) begin
                    for(int j = 0; j < ORDER; j+=1) begin
                        if(i == j) begin
                            o_mat[i*ORDER + j] <= (1<<QBITS);
                        end else begin
                            o_mat[i*ORDER + j] <= 0;
                        end
                    end
                end
                state <= INTERCHANGE;
                row <= ORDER-1; // prepare row index for diagonalize step
            end
            INTERCHANGE: begin
                if(row == 0) begin
                    state <= DIAGONALIZE;
                    divider_state <= LOAD;
                    row <= 0;
                    col <= 0;
                end else begin
                    // interchange rows of matrix
                    if(mat[(row-1)*ORDER] < mat[row*ORDER]) begin
                        for(int j = 0; j < ORDER; j++) begin
                            mat[(row-1)*ORDER + j] <= mat[row*ORDER + j];
                            mat[(row)*ORDER + j] <= mat[(row-1)*ORDER + j];
                            o_mat[(row-1)*ORDER + j] <= o_mat[row*ORDER + j];
                            o_mat[(row)*ORDER + j] <= o_mat[(row-1)*ORDER + j];
                        end
                    end
                    row <= row - 1;
                end
            end 
            DIAGONALIZE: begin
                if(row == ORDER) begin
                    state <= INVERT;
                    row <= 0;
                    col <= 0;
                    divider_state <= LOAD;
                end else begin
                    case(divider_state)
                        LOAD: begin
                            if(row == col) begin divider_state <= READY; end // shortcut into skipping this element
                            else begin
                                div_num <= mat[col*ORDER + row];
                                div_denom <= mat[row*ORDER + row];
                                div_start <= 1;
                                divider_state <= DELAY;
                            end
                        end
                        DELAY: begin
                            // delay a single cycle to ensure the divide operation begins
                            divider_state <= DIVIDE;
                            div_start <= 0;
                        end
                        DIVIDE: begin
                            if(div_done) begin
                                divider_state <= READY;
                            end
                        end
                        READY: begin
                            divider_state <= LOAD;
                            if(col < ORDER) begin
                                col <= col + 1;
                            end else begin
                                col <= 0;
                                row <= row + 1;
                            end

                            if(row != col) begin
                               for(int k = 0; k < ORDER; k++) begin
                                   mat[col*ORDER + k] <= mat[col*ORDER + k] - ((mat[row*ORDER + k] * div_result) >> QBITS);
                                   //o_mat[col*ORDER + k] <= o_mat[col*ORDER + k] - ((o_mat[row*ORDER + k] * div_result) >> QBITS);
                                   o_mat[col*ORDER + k] <= ((o_mat[row*ORDER + k] * div_result) >> QBITS);
                               end 
                            end
                        end
                    endcase 
                end
            end
            
            INVERT: begin
                if(row == ORDER) begin
                    state <= IDLE;
                    o_done <= 1;
                    row <= 0;
                    col <= 0;
                    divider_state <= LOAD;
                end else begin
                    case(divider_state)
                        LOAD: begin
                            if(row == col) begin state <= READY; end // shortcut into skipping this element
                            else begin
                                div_num <= 'b1 << QBITS;
                                div_denom <= mat[row*ORDER + row];
                                div_start <= 1;
                                divider_state <= DELAY;
                            end
                        end
                        DELAY: begin
                            // delay a single cycle to ensure the divide operation begins
                            div_start <= 0;
                            divider_state <= DIVIDE;
                        end
                        DIVIDE: begin
                            if(div_done) begin
                                divider_state <= READY;
                            end
                        end
                        READY: begin
                            if(col < ORDER) begin
                                col <= col + 1;
                            end else begin
                                col <= 0;
                                row <= row + 1;
                            end

                            for(int k = 0; k < ORDER; k++) begin
                                o_mat[row*ORDER + col] <= (o_mat[row*ORDER + col] * div_result) >> QBITS;
                            end 
                        end
                    endcase 
                end
            end
            default: begin
                
            end
        endcase
    end

endmodule
/*
 *  Much of this code was inspired by the hello world example here: https://zipcpu.com/tutorial/
 *  Many thanks to the author for the great explanations.
 */

module uart_tx #(
    parameter BAUDRATE=9600,
    parameter SYSCLOCK=12000000
) (
    input i_clk,
    input i_wr,
    input wire [7:0]i_data,
    output reg o_busy,
    output wire o_uart_tx
);

    typedef enum {TX, STOP, IDLE} state_enum;
    state_enum state;

    reg [8:0]tx_data;
    reg [23:0]counter;
    reg [4:0]tx_count;
    localparam CLOCKS_PER_BAUD = SYSCLOCK / BAUDRATE;
    reg baud_stb;

    initial begin
        o_busy = 1'b0;
        state = IDLE;
        tx_count = 0;
    end
    
    initial	baud_stb = 1'b1;
    initial	counter = 0;
    always @(posedge i_clk)
    if ((i_wr)&&(!o_busy))
    begin
        counter  <= CLOCKS_PER_BAUD - 1'b1;
        baud_stb <= 1'b0;
    end else if (!baud_stb)
    begin
        baud_stb <= (counter == 24'h01);
        counter  <= counter - 1'b1;
    end else if (state != IDLE)
    begin
        counter <= CLOCKS_PER_BAUD - 1'b1;
        baud_stb <= 1'b0;
    end

    assign o_uart_tx = tx_data[0];
    always @(posedge i_clk) begin
        if(i_wr && !o_busy) begin
            tx_data <= { i_data, 1'b0 };
        end else if(baud_stb) begin
            tx_data <= { 1'b1, tx_data[8:1] };
        end
    end

    always @(posedge i_clk) begin
        if(i_wr && !o_busy) begin
            tx_count <= 0;
            {o_busy, state} <= {1'b1, TX};
        end else if(baud_stb) begin
            case (state)
                IDLE: begin
                    {o_busy, state} <= {1'b0, IDLE};
                    tx_count <= 0;
                end
                TX: begin
                    o_busy <= 1'b1;
                    tx_count <= tx_count + 1;
                    if(tx_count == 7) begin
                        state <= STOP;      
                    end else begin
                        state <= TX;
                    end
                end
                STOP: begin
                    {o_busy, state} <= {1'b0, IDLE};
                end
                default: begin
                    
                end 
            endcase
        end
    end

endmodule
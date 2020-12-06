module uart_tx #(
    parameter BAUDRATE=100000000,
    parameter SYSCLOCK=100000000
) (
    input i_clk,
    input i_wr,
    input wire [7:0]i_data,
    output reg o_busy,
    output reg o_uart_tx
);

    typedef enum {IDLE, START, TX, STOP} state_enum;
    state_enum state;
    reg [7:0]tx_data;
    reg [31:0]counter;
    reg [4:0]tx_count;
    localparam CLOCKS_PER_BAUD = SYSCLOCK / BAUDRATE;
    wire baud_stb;

    initial begin
        o_busy = 1'b0;
        o_uart_tx = 1'b1;
        state = IDLE;
        tx_count = 0;
        counter = CLOCKS_PER_BAUD - 1;
    end

    assign baud_stb = (counter == 0);
    always @(posedge i_clk) begin
        if (counter == 0) begin
            counter <= CLOCKS_PER_BAUD - 1;
        end else if(i_wr && !o_busy)
            counter <= CLOCKS_PER_BAUD - 1;
        else begin
            counter <= counter - 1;
        end
    end

    // will resetting i_wr cause weirdness?
    always @(posedge i_clk) begin
        if(i_wr && !o_busy) begin
            o_busy <= 1'b1;
            state <= TX;
            tx_data <= i_data;
            o_uart_tx <= 1'b0;
            tx_count <= 0;
        end
    end

    // TODO(heidt) this seems weird, and there are probably lots of latches
    always @(posedge i_clk) begin
        if (baud_stb) begin
            if (state == TX) begin
                o_busy <= 1'b1;
                tx_count <= tx_count + 1;
                if(tx_count < 7) begin
                    tx_data <= {1'b1, tx_data[7:1]};
                    o_uart_tx <= tx_data[0];
                    state <= TX;
                end else begin
                    tx_data <= 0;
                    o_uart_tx <= 1'b1;
                    state <= STOP;
                end
            end else if (state == IDLE) begin
                o_uart_tx <= 1'b1;
                o_busy <= 1'b0;
                state <= IDLE;
            end else if(state == STOP) begin
                o_busy <= 1'b0;
                o_uart_tx <= 1'b1;
                state <= IDLE;
            end
        end
    end


endmodule
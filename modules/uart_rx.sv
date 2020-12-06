
module uart_rx #(
    parameter BAUDRATE=115200,
    parameter SYSCLOCK=100000000
) (
    input wire i_uart_rx,
    input wire i_clk,
    output reg [7:0]o_uart_data
    output reg o_data_ready;
);
    typedef enum {IDLE, READ, STOP} state_t;
    state_t state;
    wire baud_stb;
    reg [31:0]counter;
    reg [4:0]data_idx; // TODO(heidt) probably a better way to do size with log
    localparam CLOCKS_PER_BAUD = SYSCLOCK / BAUDRATE;

    //TODO(heidt) add oversampling
    //TODO(heidt) add frame error check

    assign baud_stb = (counter == 0)
    initial begin
        state = IDLE;
        counter = 0;
        o_data_ready = 0;
    end

    always @(posedge i_clk) begin
       if(counter == 0) begin
           counter <= CLOCKS_PER_BAUD - 1;
       end else if(state == IDLE) begin
           counter <= CLOCKS_PER_BAUD -1;
       end else begin
           counter <= counter - 1;
       end
    end

    always @(posedge i_clk) begin
        if(state == IDLE) begin
            data_idx <= 0;
            if(i_uart_rx == 0) begin
                o_data_ready <= 0;
                state <= READ;
            end
        end else begin
           if(baud_stb) begin
               if(data_idx == 8) begin
                   o_data_ready <= 1;
                   state <= IDLE;    
               end else begin
                   o_data_ready <= 0;
                   state <= READ;
                   o_uart_data[data_idx] <= i_uart_rx;
                   data_idx <= data_idx + 1;
               end
           end 
        end
    end

endmodule
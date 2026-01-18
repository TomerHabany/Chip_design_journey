//uart_tx module
`timescale 1ns / 1ps
module uart_tx
#(
    parameter TICKS_PER_BIT = 16, // Number of baud ticks per bit
    parameter DATA_WIDTH   = 8   // Number of data bits
)
(
    input  logic        clk,         // system clock
    input  logic        rst_n,       // active low reset
    input  logic [DATA_WIDTH-1:0] din,   // data to transmit
    input  logic        tx_start,    // signal to start transmission
    input  logic        sample_tick, // sample rate tick from baud generator
    output logic       tx_out,   // serial transmit output
    output logic       tx_done,      // transmission done tick
    output logic       baude_en     // baud enable signal
);

// Internal signals
// 1. output logic and register
logic tx_next; 
logic tx_reg; 

// 2. tick counter (0-TICKS_PER_BIT-1)
logic [$clog2(TICKS_PER_BIT)-1:0] tick_count_next; 
logic [$clog2(TICKS_PER_BIT)-1:0] tick_count_reg; 

// 3. bit counter (0- DATA_WIDTH -1)
logic [$clog2(DATA_WIDTH)-1:0] bit_count_next; 
logic [$clog2(DATA_WIDTH)-1:0] bit_count_reg; 

// 4. transmit data combinational and register logic
logic [DATA_WIDTH-1:0] tx_data_next; 
logic [DATA_WIDTH-1:0] tx_data_reg; 

// 5. transmission done signal
logic tx_done_next;
logic tx_done_reg;

// 6. baude enable signal
logic baude_en_next;
logic baude_en_reg;

// State machine sequential logic
typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
} state_t; 
state_t state_next;
state_t state_reg;

// combinational assignments
assign tx_out = tx_reg;
assign tx_done = tx_done_reg;
assign baude_en = baude_en_reg;

// sequential logic
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // reset all registers
        state_reg <= IDLE;
        tx_reg <= 1'b1; // idle state of tx_out is high
        tick_count_reg <= '0;
        bit_count_reg <= '0;
        tx_data_reg <= '0;
        tx_done_reg <= 1'b0;
        baude_en_reg <= 1'b0;
    end else begin
        // update all registers
        state_reg <= state_next;
        tx_reg <= tx_next;
        tick_count_reg <= tick_count_next;
        bit_count_reg <= bit_count_next;
        tx_data_reg <= tx_data_next;
        tx_done_reg <= tx_done_next;
        baude_en_reg <= baude_en_next;
    end
end

// combinational logic for next state and outputs
always_comb begin
        // default assignments keep current values
     state_next = state_reg;
     tx_next = tx_reg;
     tick_count_next = tick_count_reg;
     bit_count_next = bit_count_reg;
     tx_data_next = tx_data_reg;
     tx_done_next = 1'b0; // default no done tick
     baude_en_next = (state_reg != IDLE); // enable baud generator when not in IDLE

        case(state_reg)

        IDLE: begin
            tx_next = 1'b1; // idle state
            if (tx_start) begin
                state_next = START;
                tx_data_next = din; // load data to transmit
                tick_count_next = '0;
            end
        end   

        START: begin
            tx_next = 1'b0  ; // start bit
            if (sample_tick) begin
                if (tick_count_reg == TICKS_PER_BIT - 1) begin
                    state_next = DATA;
                    tick_count_next = '0;
                    bit_count_next = '0;
                end else begin
                    tick_count_next = tick_count_reg + 1;
                end
            end
        end

        DATA: begin 
            tx_next = tx_data_reg[0];                            // transmit LSB first
            if (sample_tick) begin                               // on each sample tick
                if (tick_count_reg == TICKS_PER_BIT - 1) begin  // reached bit duration > reset tick count
                    tick_count_next = '0;                       
                    if (bit_count_reg == DATA_WIDTH - 1) begin  // last data bit transmitted
                        state_next = STOP;                      // move to stop state
                        bit_count_next = '0;                    // reset bit count    
                    end else begin
                        bit_count_next = bit_count_reg + 1;      // increment bit count
                        tx_data_next = tx_data_reg >> 1;        // shift right to get next bit
                    end
                end else begin
                    tick_count_next = tick_count_reg + 1;       // increment tick count
                end
            end
        end

        STOP: begin
            tx_next = 1'b1;         // stop bit
            if (sample_tick) begin
                if (tick_count_reg == TICKS_PER_BIT - 1) begin
                    state_next = IDLE;
                    tx_done_next = 1'b1; // signal transmission done
                    tick_count_next = '0;
                end else begin
                    tick_count_next = tick_count_reg +1;
                end
            end
        end
        endcase
    end
endmodule


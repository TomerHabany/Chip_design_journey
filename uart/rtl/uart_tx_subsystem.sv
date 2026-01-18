// uart_tx subsystem -- connecting uart_tx and baud_gen modules
module uart_tx_subsystem
#( 
   parameter TICKS_PER_BIT = 16, // Number of baud ticks per bit
   parameter DATA_WIDTH   = 8,    // Number of data bits
   parameter BAUD_RATE    = 115_200, // Baud rate for transmission
   parameter CLOCK_FREQ   = 100_000_000 // System clock frequency
)
(
    input  logic        clk,         // system clock
    input  logic        rst_n,       // active low reset
    input  logic [DATA_WIDTH-1:0] din,   // data to transmit
    input  logic        tx_start,    // signal to start transmission
    output logic       tx_out,       // serial transmit output
    output logic       tx_done       // transmission done tick
);

// Internal signals
logic sample_tick;
logic baude_en;

// Instantiate baud generator
baud_gen #(
    .CLOCK_FREQ(CLOCK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) baud_gen_inst (
    .clk(clk),
    .rst_n(rst_n),
    .en(baude_en),
    .sample_tick(sample_tick)
);

// Instantiate uart transmitter
uart_tx #(
    .TICKS_PER_BIT(TICKS_PER_BIT),
    .DATA_WIDTH(DATA_WIDTH)
) uart_tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .din(din),
    .tx_start(tx_start),
    .sample_tick(sample_tick),
    .tx_out(tx_out),
    .tx_done(tx_done),
    .baude_en(baude_en)
);

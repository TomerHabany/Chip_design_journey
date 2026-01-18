// baud generator module
`timescale 1ns / 1ps
module baud_gen
#(
    parameter CLOCK_FREQ = 100_000_000, // 100 MHz
    parameter BAUD_RATE  = 115_200
)
(
    input  logic  clk,        // system clock
    input  logic  rst_n,      // active low reset
    input  logic  en,     // enable baud generator
    output logic  sample_tick   // sample rate tick output
);
// Calculate the number of clock cycles per baud tick
localparam integer TICK_LIMIT = CLOCK_FREQ / (BAUD_RATE*16);
localparam integer TICK_WIDTH = $clog2(TICK_LIMIT);

// count signal
logic [TICK_WIDTH-1:0] tick_count;

// baud tick generation and counter logic
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tick_count <= '0;
        sample_tick <= 1'b0;
    end else if(!en) begin
        tick_count <= '0;
        sample_tick <= 1'b0; // no tick when disabled
    end else begin                
        if(tick_count == TICK_LIMIT - 1) begin
            tick_count <= '0;
            sample_tick <= 1'b1; // generate sample tick
        end else begin
            tick_count <= tick_count + 1;
            sample_tick <= 1'b0;  // no tick     
        end
    end
endmodule

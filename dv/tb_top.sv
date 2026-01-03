// Testbench for the top module -- the clock
module tb_top ( 
 input logic clk,  // Driven by C++
  output logic [7:0] count  // Observed by waveform viewer
);
logic rst_n;
logic en;
// connect the counter
counter #(.width(8)) u_counter (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .count(count)
);

// Test sequence
initial begin
    rst_n = 0;
    en = 0;
    repeat (10) @(posedge clk);
    rst_n = 1;  // Release reset
    repeat (5) @(posedge clk);
    en = 1;  // Enable counting
    repeat (50) @(posedge clk);
    $display ("done! counter value: %0d", count);
    $finish;
end
endmodule

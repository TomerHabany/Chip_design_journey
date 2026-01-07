//counter.sv
// A professional SystemVerilog parameterized counter module
module counter #( 
    parameter width = 8  // Width of the counter
)(
    input logic clk,    // Clock input
    input logic rst_n,  // Active low reset
    input logic en,     // Enable signal
    output logic [width-1:0] count  // Counter output
);
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= '0;  // Reset counter to 0
    end else if (en) begin
        count <= count + 1;  // Increment counter
    end
end
endmodule

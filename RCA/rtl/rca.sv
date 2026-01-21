//parameterized ripple carry adder module
`timescale 1ns/1ps

module rca #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic             cin,
    output logic [WIDTH-1:0] sum,
    output logic             cout
);
logic [WIDTH:0] carry_chain;
assign carry_chain[0] = cin;

// declare genvar loop variable
genvar i;

// generate block to instantiate multiple 1-bit adders
generate
    for (i = 0; i < WIDTH; i = i + 1) begin : adder_loop
        adder_1bit u_adder_1bit (
            .a   (a[i]),
            .b   (b[i]),
            .cin (carry_chain[i]),
            .sum (sum[i]),
            .cout(carry_chain[i+1])
        );
    end
endgenerate
assign cout = carry_chain[WIDTH];

endmodule  

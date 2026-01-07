// a 1 bit adder module
`timescale 1ns/1ps
module adder_1bit (
    input logic  a,
    input logic  b,
    input logic  cin,
    output logic sum,
    output logic cout
);
    assign #1 sum = a ^ b ^ cin;
    assign #1 cout = (a & b) | (cin & (a ^ b));
endmodule

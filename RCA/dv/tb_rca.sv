// Testbench for ripple carry adder with built in adder value comparison
`timescale 1ns/1ps
module tb_rca;
    // parameters
    parameter WIDTH = 16;
    // signals
    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic             cin;
    logic [WIDTH-1:0] sum;
    logic             cout;

    // expected outputs
    logic [WIDTH:0] expected_value;
    

    // instantiate the rca module
    rca #(
        .WIDTH(WIDTH)
    ) uut (
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum),
        .cout(cout)
    );

    // test procedure
    initial begin
    // display header
    $display("Starting RCA Test..."); 
    $dumpfile("waveform.vcd"); // VCD file for waveform viewing
    $dumpvars(0, tb_rca); // dump all variables in this module
    // run multiple test cases
    repeat (20) begin
        // generate random inputs
        a   = 16'($urandom_range(0, 2**WIDTH-1));
        b   = 16'($urandom_range(0, 2**WIDTH-1));
        cin = 1'($urandom_range(0, 1));
        // compute expected outputs
        expected_value = 17'(a) + 17'(b) + 17'(cin);
        // wait for a short time to allow outputs to stabilize
        #20;
        // check results
        if (sum !== expected_value[WIDTH-1:0] || cout !== expected_value[WIDTH]) begin
            $error("Test failed for a=%0d, b=%0d, cin=%0d: expected value=%0d, cout=%0d but got sum=%0d, cout=%0d",
                   a, b, cin, expected_value[WIDTH-1:0], expected_value[WIDTH], sum, cout);
        end else begin
            $display("Test passed for a=%0d, b=%0d, cin=%0d: sum=%0d, cout=%0d",
                     a, b, cin, sum, cout);
        end
    end
    $display("RCA Test completed.");
    $finish;
    end
endmodule

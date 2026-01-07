//
`timescale 1ns/1ps

module tb_fifo(
    input logic clk
);

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;
    /* verilator lint_off UNUSEDPARAM */
    parameter CLK_PERIOD = 10;
    /* verilator lint_on UNUSEDPARAM */

    // DUT signals
    logic rst_n;
    logic wr_en;
    logic rd_en;
    logic [DATA_WIDTH-1:0] din;
    logic [DATA_WIDTH-1:0] dout;
    logic full;
    logic empty;
    /* verilator lint_off UNUSEDSIGNAL */
    logic almost_full;
    logic almost_empty;
    /* verilator lint_on UNUSEDSIGNAL */

    //queue instance
    logic [DATA_WIDTH-1:0] queue [$];

    // Instantiate the FIFO
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty)
    );

    initial begin

        // 1. Declare local variable for random data
        logic [DATA_WIDTH-1:0] temp_data;

        // Initialize signals
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        din = '0;

        // wait 2 clock cycles
        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        
        // loop to write data into FIFO
        for (int i=0; i<20; i=i+1) begin
            temp_data = $urandom_range(2**DATA_WIDTH-1, 0);
            write_data(temp_data);
            read_data();
        end
        repeat (2) @(posedge clk);

        // loop to check full condition
        for (int i=0; i<(DEPTH+4); i=i+1) begin
            temp_data = $urandom_range(2**DATA_WIDTH-1, 0);
            write_data(temp_data);
        end
        //check full flag
        if (!full) begin
            $error("FIFO should be full but full flag is not set.");
        end else begin
            $display("FIFO full flag is correctly set.");
        end 
    repeat (2) @(posedge clk);

        // loop to read all data from FIFO
        for (int i=0; i<(DEPTH+4); i=i+1) begin
            read_data();
        end
        //check empty flag
        if (!empty) begin
            $error("FIFO should be empty but empty flag is not set.");
        end else begin
            $display("FIFO empty flag is correctly set.");
        end 

        // Finish simulation
        $finish;
    end
        //task write data from queue
        task write_data(input [DATA_WIDTH-1:0] data);
            begin
                @(negedge clk);
                din = data;
                wr_en = 1;
                queue.push_back(data);

                @(negedge clk);
                wr_en = 0;
            end
        endtask

        //task read data
        task read_data();
        logic [DATA_WIDTH-1:0] expected_data;
            begin
                expected_data = queue.pop_front();
                @(negedge clk);
                rd_en = 1;
                @(negedge clk);
                rd_en = 0;
                
                // check data
                if (dout !== expected_data) begin
                    $error("Data mismatch! Expected: %h, Got: %h", expected_data, dout);
                end else begin
                    $display("Data match! Expected: %h, Got: %h", expected_data, dout);
                end
            end
        endtask
endmodule   

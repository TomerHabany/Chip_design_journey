// tb_fifo.sv - Testbench for FIFO Module

`timescale 1ns/1ps

// --- FIFO Interface Definition ---
interface fifo_if #(parameter DATA_WIDTH = 8, DEPTH = 16) (input logic clk);    // Clock input from the testbench
    logic rst_n, wr_en, rd_en, full, empty;                                     // top-level signals
    logic [DATA_WIDTH-1:0] din, dout;                                           // Data signals

// --- Interface Modport for Testbench ---  
// This modport defines the direction of signals for the testbench
    modport tb (
        input clk, dout, full, empty,
        output rst_n, wr_en, rd_en, din
    );
endinterface

// --- Testbench Module ---
module tb_fifo();
    logic clk;                          // Generating clock signal
   initial begin                        // Initial block to set initial clock value
    clk = 0;
end

always #5 clk <= ~clk;                  // Clock generation: 10ns period (100MHz)

// --- Instantiate FIFO Interface ---
    fifo_if #(8, 16) fifo_vif(.clk(clk));   // virtual interface instance

// --- Instantiate DUT ---
    fifo #(.DATA_WIDTH(8), .DEPTH(16)) dut (
        .clk(clk), .rst_n(fifo_vif.rst_n), .wr_en(fifo_vif.wr_en),
        .rd_en(fifo_vif.rd_en), .din(fifo_vif.din), .dout(fifo_vif.dout),
        .full(fifo_vif.full), .empty(fifo_vif.empty)
    );

// --- Instantiate Test Module ---
    test t1 (fifo_vif.tb);      // Pass the modport of the interface to the test module
endmodule


// --- Test Module Definition ---
module test#(parameter DATA_WIDTH = 8, DEPTH = 16) (fifo_if.tb ifc);        // Use the testbench modport of the interface 
    logic [7:0] temp_data, expected_output, scoreboard_queue[$];     // Temporary data storage and scoreboard queue

// --- Tasks Definition ---
// Task 1: Reset DUT
    task reset_dut();
        ifc.rst_n <= 1'b0; 
        ifc.wr_en <= 1'b0;
        ifc.rd_en <= 1'b0;
        @(posedge ifc.clk);                 // Wait 1 cycle before releasing reset
        ifc.rst_n <= 1'b1; 
        $display("[%0t] DUT Reset Completed", $time);
    endtask

// Task 2: Write Data to FIFO
    task write_data(input logic [7:0] data_in);     
        if (!ifc.rst_n) return;                                         // Abort if reset is active
        if (ifc.full) begin                                             // Check FIFO full status
            ifc.din   <= data_in;                                       // Load data to be written    
            ifc.wr_en <= 1'b1;
            $display("[%0t] Error: FIFO Full, write ignored", $time);
            @(posedge ifc.clk);                                         // Wait 1 cycle before proceeding     
            ifc.wr_en <= 1'b0;                  
        end else begin                                                  // If not full
            ifc.din   <= data_in;                                       // Load data to be written    
            ifc.wr_en <= 1'b1;                                          // Enable write      
            @(posedge ifc.clk);                                         // Wait for 1 clock cycle
            ifc.wr_en <= 1'b0;                                          // Disable write     
            if(ifc.rst_n) begin        
            $display("[%0t] Wrote data: %0h", $time, data_in);
            end
        end
    endtask 

// Task 3: Read Data from FIFO
    task read_data(output logic [7:0] data_out);
            if (!ifc.rst_n) return;                                     // Abort if reset is active
            if (ifc.empty) begin                                       // Check FIFO empty status
            ifc.rd_en <= 1'b1;  
            $display("[%0t] Error: FIFO Empty, read ignored", $time);
            @(posedge ifc.clk);                                    // Wait 1 cycle before proceeding
            ifc.rd_en <= 1'b0; 
        end else begin                                     // If not empty
            ifc.rd_en <= 1'b1;                             // Enable read
            @(posedge ifc.clk);                            // Wait for 1 clock cycle
            
            data_out = ifc.dout;                         // Capture read data
            ifc.rd_en <= 1'b0;                           // Disable read
            $display("[%0t] Read data: %0h", $time, data_out);            
        end
    endtask
    
// --- Test Scenarios ---
    initial begin
        //step 1: reset DUT
        @(posedge ifc.clk);
        ifc.wr_en <= 0; ifc.rd_en <= 0; ifc.din <= 0;
        reset_dut();

        //step 2: Fill Test
        @(posedge ifc.clk);
        $display("\n--- Scenario 1: Fill Test ---");
        for (int i = 1; i < DEPTH + 5; i++) begin                         // Attempt to write more than DEPTH to test full condition
             write_data(i[7:0]);             
        end

        //step 3: Empty Test
        $display("\n--- Scenario 2: Empty Test ---");
        for (int i = 1; i < DEPTH + 5; i++) begin                       // Attempt to read more than DEPTH to test empty condition
            read_data(temp_data);
            if (!ifc.empty) begin                                               
                 if (temp_data !== i[7:0]) begin                                     // Verify read data against expected value
                    $error("Mismatch! Expected %0h, Got %0h", i[7:0], temp_data);
                end
            end            
        end

        // Step 4: Simultaneous Read/Write Test
        $display("\n--- Scenario 3: Simultaneous R/W ---");
        fork                                                // Fork-Join to perform read and write simultaneously
            begin : writer                                  // Writer process
                for (int i = 0; i < DEPTH + 10; i++) begin
                    logic [7:0] val = $urandom;             // Generate random data into loop parameter 'val'
                    if (!ifc.full) begin
                    scoreboard_queue.push_back(val);        // Store expected data in scoreboard
                    end
                    write_data(val);                        // Write data to FIFO
                end
            end
            begin : reader     // Reader process
                repeat(5) @(posedge ifc.clk);                        // Initial delay to allow some writes to accumulate
                for (int i = 0; i < DEPTH + 10; i++) begin
                    read_data(temp_data);                           // Read data from FIFO
                    if (scoreboard_queue.size() > 0) begin         // Check if scoreboard has expected data
                        expected_output = scoreboard_queue.pop_front();         // Get expected data from scoreboard
                        if (temp_data !== expected_output) begin                // Compare read data with expected data
                            $error("Scoreboard Mismatch! Exp: %0h, Got: %0h", expected_output, temp_data);
                        end                   
                    end
                end
            end  
        join
        
     // Step 5: Reset During Operation (Stress Test)
     $display("\n--- Scenario 4: Reset During Operation ---");

     // 1. Fill the FIFO halfway
     for (int i = 0; i < DEPTH/2; i++) begin
        write_data(i[7:0]);
      end

        fork
            // Thread 1: Continuous Writing
            begin
                for (int i = 0; i < DEPTH; i++) write_data($urandom);
            end
            // Thread 2: Continuous Reading
            begin
                for (int i = 0; i < DEPTH; i++) read_data(temp_data);
            end
            // Thread 3: Surprise Reset!
            begin
                #23; // Wait for some random time mid-transfer
                $display("[%0t] !!! CRITICAL: Issuing Unexpected Reset !!!", $time);
                ifc.rst_n <= 1'b0;
                @(posedge ifc.clk);
                ifc.rst_n <= 1'b1;
            end
        join_any // We join as soon as the reset thread finishes
        disable fork; // Kill the remaining R/W threads

     // 2. Verification after Reset

            if (ifc.full !== 0 || ifc.empty !== 1 || dut.wr_ptr !== 0 || dut.rd_ptr !== 0) begin
            $error("Post-Reset Error: FIFO not in clean state! Full: %b, Empty: %b wr_ptr: %b rd_ptr: %b", ifc.full, ifc.empty, dut.wr_ptr, dut.rd_ptr);
        end else begin
            $display("[%0t] Post-Reset Check Passed: FIFO is empty and pointers are reset.", $time);
        end

     // 3. Clear the scoreboard queue because the data is now gone
        scoreboard_queue.delete();
        #5;
        $display("\n---No Errors detected!!!! Test Completed Successfully---");
        $finish;
    end


// --- Monitor Process ---
    initial begin
        forever begin               // Continuously monitor FIFO status
            @(posedge ifc.clk);     // Check status at every clock edge
            
            if (ifc.full)  $display("  [MONITOR] FIFO is FULL");
            if (ifc.empty) $display("  [MONITOR] FIFO is EMPTY");
        end
    end
endmodule

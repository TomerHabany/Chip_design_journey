`timescale 1ns/1ps
// Parameterized Synchronous FIFO Module
// Supports configurable data width and depth
module fifo
#(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)
(
    input logic clk,
    input logic rst_n,
    input logic wr_en,
    input logic rd_en,
    input logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout,
    output logic full,
    output logic empty,
    output logic almost_full,
    output logic almost_empty
);

    // Memory array
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Pointer and Count Widths
    localparam PTR_WIDTH = $clog2(DEPTH);
    logic [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
    logic [PTR_WIDTH:0] count; 

    logic wr_valid = wr_en && !full;
    logic rd_valid = rd_en && !empty;

    // CONTROL LOGIC
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            // Write Pointer logic
            if (wr_valid) begin
                if (wr_ptr == (PTR_WIDTH)'(DEPTH-1)) 
                    wr_ptr <= 0;
                else                   
                    wr_ptr <= wr_ptr + 1'b1;
            end

            // Read Pointer logic
            if (rd_valid) begin
                if (rd_ptr == (PTR_WIDTH)'(DEPTH-1)) 
                    rd_ptr <= 0;
                else                   
                    rd_ptr <= rd_ptr + 1'b1;
            end
            
            // Count tracking
            case ({wr_valid, rd_valid})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count; 
            endcase
        end
    end

    // Status flags
    assign full         = (count == (PTR_WIDTH+1)'(DEPTH));
    assign empty        = (count == 0);
    assign almost_full  = (count >= (PTR_WIDTH+1)'(DEPTH - 2)); 
    assign almost_empty = (count <= 2);

    // DATA PATH
    always_ff @(posedge clk) begin
        if (wr_valid) mem[wr_ptr] <= din;
    end

    // memory read logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 0;
        end else if (rd_valid) begin
            dout <= mem[rd_ptr];
        end
        end
    
    
endmodule


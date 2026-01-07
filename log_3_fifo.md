<h1>🌌 Log 3: The Synchronous FIFO</h1>

<p align="center">
  <b>A Journey from Fresh Graduate to Silicon Engineer</b><br>
  <i>Moving from combinational gates to sequential buffering logic.</i>
</p>



<h3>🚀 The Mission: Sequential Logic & Buffering</h3>
<p>In Log 2, we built an adder where signals "rippled" through gates. Now, we move into <b>Sequential Logic</b>. We are building a <b>Synchronous FIFO (First-In, First-Out)</b>. Think of this as the "waiting room" of digital design—it’s a buffer used to manage data flow between different modules.</p>

<hr>
<hr>

<h2>🧪 The Module (<code>fifo.sv</code>)</h2>

<h3>🏗️ 1. The Interface and Memory Array</h3>

<p><b>The Goal:</b><br>
We need a storage buffer that handles data in a specific order: the first piece of data written must be the first one read. Our first step is to define the interface (how the world talks to us) and the physical storage (where the data sits).</p>

<p><b>Interface (Inputs & Outputs):</b></p>
<ul>
    <li><b>clk:</b> The system clock.</li>
    <li><b>rst_n:</b> Active-low asynchronous reset.</li>
    <li><b>wr_en:</b> Write enable command.</li>
    <li><b>rd_en:</b> Read enable command.</li>
    <li><b>din:</b> Data input bus.</li>
    <li><b>dout:</b> Data output bus.</li>
</ul>

<p><b>Internal Signals:</b><br>
To manage the "shelves" of our memory, we need a <b>Memory Array</b> (<code>mem</code>). We use parameters so we can change the size of these shelves without rewriting the code.</p>



<p><b>The Code So Far:</b></p>
<details open>
<summary><b>📄 rtl/fifo.sv (Interface)</b></summary>
<pre><code>
module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input  logic clk,
    input  logic rst_n,
    input  logic wr_en,
    input  logic rd_en,
    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout,
    output logic full,
    output logic empty,
    output logic almost_full,
    output logic almost_empty
);

    // Memory array: Our physical storage "shelves"
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Pointer and Count Widths
    localparam PTR_WIDTH = $clog2(DEPTH);
    logic [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
    logic [PTR_WIDTH:0] count; 

endmodule
</code></pre>
</details>

<hr>

<h3>🚩 2. Status Flags (The Early Warning System)</h3>

<p><b>The Goal:</b><br>
Before we move pointers, we need to know the limits. We need signals that tell us when the FIFO is totally full or empty, but we also want "Almost" flags.</p>

<p><b>Breaking Down the Logic:</b><br>
We use simple comparisons against our <code>count</code> variable.</p>
<ul>
    <li><b>Full/Empty:</b> These are hard stops. If <code>full</code> is high, we cannot write.</li>
    <li><b>Almost Full/Empty:</b> In real-world high-speed designs, it takes time for a system to react to a "Full" signal. <code>almost_full</code> acts as an <b>Early Warning</b>, telling the sender to "Slow down, I'm nearly out of room!" before an overflow occurs.</li>
</ul>

<p><b>The Code So Far (Updated):</b></p>
<details open>
<summary><b>📄 rtl/fifo.sv (Flags)</b></summary>
<pre><code>
// ... (previous interface and memory logic) ...

    // Status flags: Continuous logic based on the current count
    assign full         = (count == (PTR_WIDTH+1)'(DEPTH));
    assign empty        = (count == 0);
    
    // Early Warnings: Set when we are within 2 slots of the limit
    assign almost_full  = (count >= (PTR_WIDTH+1)'(DEPTH - 2)); 
    assign almost_empty = (count <= 2);

endmodule
</code></pre>
</details>

<hr>

<h3>🧠 3. Control Logic (Pointers & Counter)</h3>

<p><b>The Goal:</b><br>
Now we need the "brain" to manage our pointers. We need to track where to write next and where to read from.</p>

<p><b>Internal Signals & Strategy:</b><br>
We create two pointers: <code>wr_ptr</code> and <code>rd_ptr</code>. We treat the memory as a <b>Circular Buffer</b>—when a pointer reaches the last shelf, it wraps back to zero. To keep everything safe, we use <code>wr_valid</code> and <code>rd_valid</code> wires to combine user intent (<code>en</code>) with the safety flags.</p>



<p><b>The Code So Far (Updated):</b></p>
<details open>
<summary><b>📄 rtl/fifo.sv (Control Logic)</b></summary>
<pre><code>
// ... (previous flags and memory logic) ...

    // Validation logic: Ensure we only act when it's safe
    wire wr_valid = wr_en && !full;
    wire rd_valid = rd_en && !empty;

    // CONTROL LOGIC: Moving the pointers and tracking the count
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            // Move Write Pointer: Increment or wrap to 0
            if (wr_valid) begin
                wr_ptr <= (wr_ptr == (PTR_WIDTH)'(DEPTH-1)) ? 0 : wr_ptr + 1'b1;
            end

            // Move Read Pointer: Increment or wrap to 0
            if (rd_valid) begin
                rd_ptr <= (rd_ptr == (PTR_WIDTH)'(DEPTH-1)) ? 0 : rd_ptr + 1'b1;
            end
            
            // Count tracking: Monitoring exactly how many items are inside
            case ({wr_valid, rd_valid})
                2'b10: count <= count + 1'b1; // Write only
                2'b01: count <= count - 1'b1; // Read only
                default: count <= count;      // Both or neither
            endcase
        end
    end
</code></pre>
</details>

<hr>

<h3>📦 4. Data Path (The Move)</h3>

<p><b>The Goal:</b><br>
Finally, we connect the logic to the actual storage. This is where the bits are physically latched into the memory array based on our pointers.</p>

<p><b>The Code So Far (The Complete Module):</b></p>
<details open>
<summary><b>📄 rtl/fifo.sv (Complete)</b></summary>
<pre><code>
// ... (all previous logic) ...

    // DATA PATH: Physically writing data into the array
    always_ff @(posedge clk) begin
        if (wr_valid) mem[wr_ptr] <= din;
    end

    // DATA PATH: Physically reading data out of the array
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 0;
        end else if (rd_valid) begin
            dout <= mem[rd_ptr];
        end
    end
    
endmodule
</code></pre>
</details>

<hr>

<hr>

<h2>🧪 The Automated Testbench (<code>tb_fifo.sv</code>)</h2>

<p><b>The Goal:</b><br>
No design is complete without proof. We need to create a test environment that throws random data at our FIFO and automatically checks if the order remains "First-In, First-Out."</p>

<hr>

<h3>🏗️ 1. Parameters, Signals, and the Golden Queue</h3>
<p><b>The Goal:</b><br>
First, we set up the environment. This includes defining the clock, matching the RTL parameters, and connecting our "Device Under Test" (DUT).</p>

<p><b>The Strategy:</b><br>
To verify the hardware, we use a <b>Queue (<code>[$]</code>)</b>. In SystemVerilog, a queue is a variable-sized array that acts as a built-in software FIFO. We use it as our <b>Golden Reference</b>:</p>
<ul>
    <li><b><code>push_back()</code></b>: Adds an item to the end of the line (The Write).</li>
    <li><b><code>pop_front()</code></b>: Removes the oldest item from the front (The Read).</li>
</ul>
<p>By mirroring every hardware move in this software queue, we can automatically detect if the hardware makes a mistake.</p>



<p><b>The Code So Far:</b></p>
<details open>
<summary><b>📄 tb/tb_fifo.sv (Setup)</b></summary>
<pre><code>
module tb_fifo(
    input logic clk
);
    // 1. Parameters matching the RTL
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;

    // 2. DUT signals
    logic rst_n;
    logic wr_en;
    logic rd_en;
    logic [DATA_WIDTH-1:0] din;
    logic [DATA_WIDTH-1:0] dout;
    logic full;
    logic empty;
    logic almost_full;
    logic almost_empty;

    // 3. Queue instance: Our software mirror
    logic [DATA_WIDTH-1:0] queue [$];

    // 4. Instantiate the FIFO
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
endmodule
</code></pre>
</details>

<hr>

<h3>🛠️  2. Verification Tasks (The Drivers)</h3>
<p><b>The Goal:</b><br>
Instead of toggling signals manually for every operation, we use <b>Tasks</b> to handle the communication with the hardware.</p>

<p><b>What is a Task?</b><br>
A <code>task</code> in SystemVerilog is a block of code that can be called multiple times. Unlike functions, tasks can contain time-consuming statements (like <code>@(posedge clk)</code>), making them perfect for driving hardware signals over several clock cycles.</p>

<p><b>The Two Tasks we are writing:</b></p>
<ol>
    <li><b><code>write_data</code></b>: Handles the timing for a write operation and pushes that same data into our software <code>queue</code>.</li>
    <li><b><code>read_data</code></b>: Pops the "correct" value from the <code>queue</code> and compares it against what the hardware actually produces (<code>dout</code>).</li>
</ol>

<p><b>The Code So Far (Updated):</b></p>
<details open>
<summary><b>📄 tb/tb_fifo.sv (Tasks)</b></summary>
<pre><code>
// ... (previous setup and instantiation) ...

    task write_data(
        input [DATA_WIDTH-1:0] data
    );
        begin
            @(negedge clk); // Drive on negedge to avoid race conditions
            din = data;
            wr_en = 1;
            queue.push_back(data); 
            @(negedge clk);
            wr_en = 0;
        end
    endtask

    task read_data();
        logic [DATA_WIDTH-1:0] expected_data;
        begin
            expected_data = queue.pop_front(); 
            @(negedge clk);
            rd_en = 1;
            @(negedge clk);
            rd_en = 0;
            
            // Automated Self-Check
            if (dout !== expected_data) 
                $error("Data mismatch! Expected: %h, Got: %h", expected_data, dout);
            else 
                $display("Data match! Expected: %h, Got: %h", expected_data, dout);
        end
    endtask
</code></pre>
</details>

<hr>

<h3>🚦  3. The Test Sequence (Initial Block)</h3>
<p><b>The Goal:</b><br>
This is where we initialize and execute the actual test plan.</p>

<p><b>Initialization:</b><br>
We begin by declaring <code>temp_data</code>. This must be at the very start of the <code>initial</code> block because SystemVerilog requires local variables to be declared before any procedural logic. Once declared, we provide stable <b>initial values</b> to our signals (<code>rst_n</code>, <code>wr_en</code>, <code>rd_en</code>, and <code>din</code>). We wait for two clock cycles under reset, then set <code>rst_n</code> to 1 to begin operations.</p>

<p><b>The Test Plan:</b></p>
<ol>
    <li><b>Simultaneous Test</b>: Write a value and immediately read it back to check basic synchronization.</li>
    <li><b>Full Logic Test</b>: Write 20 times without reading. Since our depth is 16, this checks if the <code>full</code> flag stops the overflow correctly.</li>
    <li><b>Empty Logic Test</b>: Read everything back until the FIFO is drained, checking if the <code>empty</code> flag triggers.</li>
</ol>

<p><b>The Complete Testbench Code:</b></p>
<details open>
<summary><b>📄 tb/tb_fifo.sv (Complete)</b></summary>
<pre><code>
// ... (previous setup, instantiation, and tasks) ...

    initial begin
        // Variable declaration must come first
        logic [DATA_WIDTH-1:0] temp_data;
        
        // 1. Initialize and Reset
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        din = '0;
        
        repeat (2) @(posedge clk);
        rst_n = 1; // Release reset
        @(posedge clk);
        
        // TEST 1: Write and immediately Read
        for (int i=0; i&lt;20; i=i+1) begin
            temp_data = $urandom_range(2**DATA_WIDTH-1, 0);
            write_data(temp_data);
            read_data();
        end

        // TEST 2: Checking Full Logic (Write 20 times)
        for (int i=0; i&lt;(DEPTH+4); i=i+1) begin
            temp_data = $urandom_range(2**DATA_WIDTH-1, 0);
            write_data(temp_data);
        end
        if (!full) $error("TEST FAILED: FIFO should be full.");
        else       $display("TEST PASSED: FIFO full flag is set.");

        repeat (2) @(posedge clk);

        // TEST 3: Checking Empty Logic (Drain the FIFO)
        for (int i=0; i&lt;(DEPTH+4); i=i+1) begin
            read_data();
        end
        if (!empty) $error("TEST FAILED: FIFO should be empty.");
        else        $display("TEST PASSED: FIFO empty flag is set.");

        $finish;
    end
endmodule
</code></pre>
</details>

<hr>
<hr>
<h2>⚙️ The Execution Layer: C++ Harness & Automation</h2>

<p>Like always, to run our simulation we will need to bridge the gap between our hardware code and our computer's processor. We use <b>Verilator</b> to transform our SystemVerilog into a high-performance C++ model, then use a C++ "Harness" to drive the clock and a Makefile to automate the entire process.</p>

<h3>1. The C++ Wrapper (<code>tb_fifo.cpp</code>)</h3>
<p>Since we are using a newer Verilator context, our C++ file is very clean. It serves as the master controller for the simulation, handling the "physical" aspects of time and signal tracing.</p>

<p><b>What’s happening here:</b></p>
<ul>
    <li><b>Context & Model:</b> We use <code>std::unique_ptr</code> for safe memory management of the simulation context and the FIFO model.</li>
    <li><b>The Clock Driver:</b> We manually toggle <code>top->clk</code> every 5ns. Because we initialize it to <code>0</code>, the first event the hardware sees is a crisp rising edge.</li>
    <li><b>The Waveform Link:</b> The simulation dumps every signal change into <code>fifo_waveform.vcd</code>, allowing us to visually inspect the pointers and flags later in GTKWave.</li>
</ul>



<details open>
<summary><b>📄 dv/tb_fifo.cpp</b></summary>
<pre><code>
#include &lt;iostream&gt;
#include &lt;memory&gt;
#include "Vtb_fifo.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    // Create Verilator context
    const std::unique_ptr&lt;VerilatedContext&gt; contextp{new VerilatedContext};
    contextp->commandArgs(argc, argv);

    // Instantiate the top module
    const std::unique_ptr&lt;Vtb_fifo&gt; top{new Vtb_fifo{contextp.get()}};

    // Waveform Setup
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("fifo_waveform.vcd");

    // Initialize clock to 0
    top->clk = 0;

    // Simulation Loop
    while (!contextp->gotFinish()) {
        contextp->timeInc(5);        // Advance time 5ns
        top->clk = !top->clk;        // Toggle clock (100MHz)
        top->eval();                 // Evaluate the model
        tfp->dump(contextp->time()); // Write to VCD file
    }

    tfp->close();
    std::cout &lt;&lt; "--- Simulation Finished ---" &lt;&lt; std::endl;
    return 0;
}
</code></pre>
</details>

<h3>2. The Makefile: One Command to Rule Them All</h3>
<p>Instead of typing out long Verilator commands every time we make a change, we use a <b>Makefile</b> to handle the heavy lifting. This file organizes our directory structure (<code>rtl</code> for hardware, <code>dv</code> for design verification) and manages the build rules.</p>

<details open>
<summary><b>📄 Makefile</b></summary>
<pre><code>
# Variables
VERILATOR = verilator
RTL_DIR = rtl
DV_DIR = dv
TOP_MODULE = tb_fifo

// List all source files
SRCS = $(RTL_DIR)/fifo.sv $(DV_DIR)/tb_fifo.sv $(DV_DIR)/tb_fifo.cpp

// Build rules
compile:
	$(VERILATOR) -Wall --trace --timing -sv --cc --exe --build \
		-I$(RTL_DIR) \
		$(SRCS) \
		--top-module $(TOP_MODULE) \
		-o V$(TOP_MODULE) \
		-Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM

run:
	./obj_dir/V$(TOP_MODULE)

waves:
	gtkwave fifo_waveform.vcd

clean:
	rm -rf obj_dir fifo_waveform.vcd
</code></pre>
</details>

<hr>

<h2>📝 Log 3 Final Summary</h2>

<ul>
    <li><b>✅ RTL Design:</b> Successfully implemented a Parameterized Synchronous FIFO using a circular buffer approach. We added <b>Almost Full</b> and <b>Almost Empty</b> flags as critical "early warning" indicators to manage backpressure in high-speed data streams.</li>
    <li><b>✅ Automated Verification:</b> Developed a robust testbench using <b>SystemVerilog Tasks</b> to abstract hardware signaling. By implementing a <b>Golden Reference Queue</b>, we achieved 100% automated data checking—comparing hardware output against a perfect software model in real-time.</li>
    <li><b>✅ Stress Testing:</b> Verified the FIFO under three distinct scenarios: basic throughput (Simultaneous Read/Write), overflow protection (Full flag check), and underflow protection (Empty flag check). Each test provides clear console feedback on success or failure.</li>
    <li><b>✅ Professional Infrastructure:</b> Leveraged a modern Verilator C++ harness and a multi-stage Makefile, streamlining the workflow from compilation to waveform analysis.</li>
</ul>

<hr>





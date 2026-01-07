 <i>Log 1: Building the Spacecraft - Environment Setup & Toolchain</i>
</p>

<hr>

<h3>📥 Introduction</h3>
<p>Our first step as chip designers is to establish a development environment that mimics industry standards. Most Electronic Design Automation (EDA) tools are native to Linux; therefore, we will use <b>Ubuntu (WSL2)</b> as our foundation.</p>

<p>This log covers the installation of Verilator, GTKWave, and Make, followed by the configuration of VS Code and GitHub for hardware development. Finally, we implement our very first RTL module and testbench to ensure everything is firing correctly.</p>

<hr>

<h3>🎯 Log Objectives</h3>
<p>To get this environment ready, we will navigate through these stages:</p>
<ul>
  <li><b>Operating System:</b> Implementing Ubuntu/WSL2 as the Linux foundation.</li>
  <li><b>The Toolchain:</b> Installing and configuring Verilator, GTKWave, and Make.</li>
  <li><b>Project Structure:</b> Organizing files into standard RTL and Verification folders.</li>
  <li><b>Editor:</b> Installing VS Code and connecting it to our Linux environment.</li>
  <li><b>GitHub:</b> Setting up our own Git directly in VS Code.</li>
  <li><b>Hardware Verification:</b> Simulating an 8-bit counter to confirm the tools are working.</li>
</ul>

<hr>

<h3>🛠️ The Operating System: Why Linux?</h3>
<p>In the world of silicon engineering, Linux is the non-negotiable standard. By using <b>WSL2 (Windows Subsystem for Linux)</b>, we gain access to a full Linux kernel without needing to leave Windows, providing a stable bridge for our development tools.</p>

<h4>1. Installing WSL2</h4>
<p>If you haven't set up your Linux subsystem yet, follow this guide:</p>
<blockquote>
  <a href="https://www.youtube.com/watch?v=eId6K8d0v6o">🎥 How to install WSL2 (Credit: TechTime)</a>
</blockquote>

<h4>2. The Toolchain: Verilator, GTKWave, and Make</h4>
<p>Install the complete toolchain with this command in your Ubuntu terminal:</p>
<pre><code>sudo apt update && sudo apt install -y verilator gtkwave build-essential make</code></pre>

<hr>

<h3>📂 Project Directory Structure</h3>
<p>Professional RTL development requires a clean separation between design files and verification environment. Run the following command in your Ubuntu terminal:</p>

<pre><code>mkdir -p galaxy_project/{rtl,dv,sim}</code></pre>

<ul>
  <li><b>rtl/</b>: Hardware design files (SystemVerilog).</li>
  <li><b>dv/</b>: Design Verification (Testbenches and C++ wrappers).</li>
  <li><b>sim/</b>: Temporary build files and simulation outputs.</li>
</ul>

<hr>

<hr>

<h3>🚀 Hardware Verification: The 8-bit Counter</h3>
<p>To confirm the environment is fully functional, we will build an 8-bit counter. Verification in Verilator is a "co-simulation" process: we write the hardware in <b>SystemVerilog</b> and the test harness in <b>C++</b>.</p>

<h4>Step 1: The RTL Design </h4>
<p>First, we define the actual hardware logic. This module increments a value on every clock edge when enabled.</p>
<details>
<summary><b>📄 rtl/counter.sv</b></summary>
<pre><code>
module counter #( 
    parameter width = 8 
)(
    input logic clk,    
    input logic rst_n,  
    input logic en,     
    output logic [width-1:0] count 
);
// Standard synchronous logic with active-low asynchronous reset
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) count <= '0;  
    else if (en) count <= count + 1;
end
endmodule
</code></pre>
</details>

<h4>Step 2: The SystemVerilog Testbench </h4>
<p>We wrap our design in a top-level testbench. This allows us to define the test sequence (resetting, waiting, and enabling) using hardware-centric timing.</p>
<details>
<summary><b>🧪 dv/tb_top.sv</b></summary>
<pre><code>
module tb_top ( 
    input logic clk,  
    output logic [7:0] count  
);
logic rst_n, en;

// Instantiate the Unit Under Test (UUT)
counter #(.width(8)) u_counter (
    .clk(clk), .rst_n(rst_n), .en(en), .count(count)
);

initial begin
    rst_n = 0; en = 0;
    repeat (10) @(posedge clk);
    rst_n = 1;  // Release reset
    repeat (5) @(posedge clk);
    en = 1;     // Start counting
    repeat (50) @(posedge clk);
    $display("Simulation complete! Final Count: %d", count);
    $finish;
end
endmodule
</code></pre>
</details>

<h4>Step 3: The C++ Simulation Driver </h4>
<p>Verilator converts SystemVerilog into C++. We need a C++ "wrapper" to act as the physical world: it generates the clock signal, handles the waveform dumping (.vcd), and drives the execution loop.</p>
<details>
<summary><b>⚙️ dv/sim_main.cpp</b></summary>
<pre><code>
#include "Vtb_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_top* top = new Vtb_top; // Instantiate the translated hardware

    // Initialize Waveform Tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("sim/waveform.vcd");

    int time = 0;
    while (!Verilated::gotFinish() && time < 1000) {
        top->clk = !top->clk; // Manual clock toggle
        top->eval();          // Evaluate logic
        tfp->dump(time++);    // Record signal states
    }
    tfp->close();
    delete top;
    return 0;
}
</code></pre>
</details>

<h4>Step 4: The Makefile </h4>
<p>Manually typing compilation commands is error-prone. The Makefile automates the three-stage process: <b>Verilate</b> (SV to C++), <b>Compile</b> (C++ to Binary), and <b>Run</b> (Execute Simulation).</p>
<details>
<summary><b>📜 Makefile</b></summary>
<pre><code>
VERILATOR = verilator
RTL_DIR = rtl
DV_DIR = dv
TOP_MODULE = tb_top

all: compile run

compile:
	@echo "--- Verilating and Building ---"
	$(VERILATOR) -Wall --trace --timing --cc -I$(RTL_DIR) \
		$(DV_DIR)/$(TOP_MODULE).sv --top-module $(TOP_MODULE) \
		--exe $(DV_DIR)/sim_main.cpp
	make -C obj_dir -f V$(TOP_MODULE).mk V$(TOP_MODULE)

run:
	@echo "--- Running Simulation ---"
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir sim/waveform.vcd
</code></pre>
</details>

<hr>
<h3>📝 Log 1 Summary</h3>
<p>We have successfully established an industry-standard development environment.</p>
<ul>
  <li>✅ Infrastructure: Ubuntu (WSL2).</li>
  <li>✅ Toolchain: Verilator, GTKWave, and Make.</li>
  <li>✅ Hardware Baseline: Simulated an 8-bit counter.</li>
</ul>
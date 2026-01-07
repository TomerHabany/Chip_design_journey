# 🌌 The Chip Designer's Guide to the Galaxy

<p align="center">
  <b>A Journey from Fresh Graduate to Silicon Engineer</b><br>
  <i>Log 1: Building the Spacecraft - Environment Setup & Toolchain</i>
</p>

---

### 📥 Introduction
Our first step as chip designers is to establish a development environment that mimics industry standards. Most Electronic Design Automation (EDA) tools are native to Linux; therefore, we will use **Ubuntu (WSL2)** as our foundation. 

This log covers the installation of Verilator, GTKWave, and Make, followed by the configuration of VS Code and GitHub for hardware development. Finally, we implement our very first RTL module and testbench to ensure everything is firing correctly.

---

### 🎯 Log Objectives
To get this environment ready, we will navigate through these stages:
* **Operating System:** Implementing Ubuntu/WSL2 as the Linux foundation.
* **The Toolchain:** Installing and configuring Verilator, GTKWave, and Make.
* **Project Structure:** Organizing files into standard RTL and Verification folders.
* **Editor:** Installing VS Code and connecting it to our Linux environment.
* **GitHub:** Setting up our own Git directly in VS Code.
* **Hardware Verification:** Simulating an 8-bit counter to confirm the tools are working.

---

### 🛠️ The Operating System: Why Linux?
In the world of silicon engineering, Linux is the non-negotiable standard. While Windows is excellent for general productivity, the vast majority of open-source and commercial hardware tools are designed to run in a Unix-based environment. By using **WSL2 (Windows Subsystem for Linux)**, we gain access to a full Linux kernel without needing to leave Windows, providing a stable bridge for our development tools.

#### 1. Installing WSL2
If you haven't set up your Linux subsystem yet, follow this guide:
> [🎥 How to install WSL2 (Credit: TechTime)](https://www.youtube.com/watch?v=eId6K8d0v6o)

#### 2. The Toolchain: Verilator, GTKWave, and Make
We use **Verilator** for high-performance RTL simulation, **GTKWave** for waveform analysis, and **Make** for build automation.

Install the complete toolchain with this command in your Ubuntu terminal:
```bash
sudo apt update && sudo apt install -y verilator gtkwave build-essential make
📂 Project Directory Structure
Professional RTL development requires a clean separation between design files and verification environment. Run the following command in your Ubuntu terminal:

Bash

mkdir -p galaxy_project/{rtl,dv,sim}
rtl/: Hardware design files (SystemVerilog).

dv/: Design Verification (Testbenches and C++ wrappers).

sim/: Temporary build files and simulation outputs.

✍️ Installing the Editor: VS Code
You do not install VS Code inside Ubuntu. Instead, you install it on Windows and use an extension to "tunnel" into Linux.

A. Installation & Connection
Download and install VS Code for Windows.

Follow this guide to connect VS Code to your new Linux environment:

🎥 Connecting VS Code to WSL (Credit: TechWithCosta)

B. Essential Chip Design Extensions
Once VS Code is connected to Ubuntu, you must install these extensions inside the WSL session to get code highlighting and error checking:

Verilog-HDL/SystemVerilog/Bluespec: Provides syntax highlighting and basic linting.

C/C++ (by Microsoft): Necessary for writing the C++ testbenches used by Verilator.

🐙 GitHub: Version Control and Terminal Integration
To develop like a professional, we will use the integrated terminal in VS Code to run our Linux commands without leaving the editor.

A. Opening the Integrated Terminal
In VS Code, press Ctrl + ` (the backtick key) or go to Terminal > New Terminal.

Look at the dropdown menu; it should say wsl: Ubuntu.

Any command you type here—like ls, mkdir, or git—is executed directly inside Linux.

B. Initializing Git and .gitignore
To keep your repository clean, you must prevent Git from tracking compiled binaries and large waveform files.

Initialize Git: Run git init in the terminal.

Create the .gitignore: Create a file named .gitignore in your root project folder and paste the following:

<details> <summary><b>📄 View .gitignore content</b></summary>

Plaintext

# Verilated generated files
obj_dir/
*.mk
*.dat

# Simulation waveforms
sim/*.vcd

# OS/Editor junk
.DS_Store
.vscode/
</details>

🚀 Hardware Verification: The 8-bit Counter
To confirm the environment is fully functional, we will create a simple counter and run a simulation. We will separate the "Clock Engine" (C++) from the "Test Logic" (SystemVerilog).

<details> <summary><b>📦 The Design (rtl/counter.sv)</b></summary>

Code snippet

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
</details>

<details> <summary><b>⚙️ The Clock Engine (dv/sim_main.cpp)</b></summary>

C++

#include "Vtb_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    // Create the instance using the correct class name
    Vtb_top* top = new Vtb_top; 

    // Setup Waveform Recording
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    int time = 0;
    // Run until the SystemVerilog $finish is called
    while (!Verilated::gotFinish() && time < 1000) {
        top->clk = !top->clk; // Toggle clock
        top->eval();          // Evaluate logic
        tfp->dump(time);      // Dump waves
        time++;
    }

    tfp->close();
    delete top;
    
    std::cout << "Simulation finished at time " << time << std::endl;
    return 0;
}
</details>

<details> <summary><b>🧪 The SystemVerilog Testbench (dv/tb_counter.sv)</b></summary>

Code snippet

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
</details>

<details> <summary><b>📜 The Makefile</b></summary>

Makefile

# --- Variables ---
VERILATOR = verilator
RTL_DIR = rtl
DV_DIR = dv
TOP_MODULE = tb_top

# --- Build Rules ---
all: compile run

compile:
	@echo "--- STEP 1: Verilating (Translating SV to C++) ---"
	$(VERILATOR) -Wall --trace --timing --cc \
		-I$(RTL_DIR) \
		$(DV_DIR)/$(TOP_MODULE).sv \
		--top-module $(TOP_MODULE) \
		--exe $(DV_DIR)/sim_main.cpp

	@echo "--- STEP 2: Building the Executable ---"
	make -C obj_dir -f V$(TOP_MODULE).mk V$(TOP_MODULE)

run:
	@echo "--- STEP 3: Running Simulation ---"
	./obj_dir/V$(TOP_MODULE)

# --- Cleanup ---
clean:
	@echo "Cleaning up project files..."
	rm -rf obj_dir waveform.vcd
</details>

🔭 Running Your First Simulation
Compile and Run: Type make in your VS Code terminal and press Enter.

View Results: Once finished, type gtkwave waveform.vcd and press Enter.

Analyze: In GTKWave, click on top, then u_counter. Drag the clk and count signals into the wave area to see the counter incrementing.

📝 Log 1 Summary
We have successfully established a professional, industry-standard development environment.

✅ Infrastructure: Deployed Ubuntu (WSL2) as our core Linux foundation.

✅ Toolchain: Installed Verilator, GTKWave, and Make.

✅ Workflow: Configured VS Code and Git.

✅ Hardware Baseline: Verified the entire flow by simulating an 8-bit counter.

Junior's Note: It's tempting to skip the Makefile and just run long commands. Don't. Automation is the heartbeat of real silicon design.

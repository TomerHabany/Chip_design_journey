# 🌌 The Chip Designer's Guide to the Galaxy

<p align="center">
  <b>A Journey from Fresh Graduate to Silicon Engineer</b><br>
  <i>Log 1: Building the Spacecraft - Environment Setup & Toolchain</i>
</p>

---

### 📥 Introduction
Our first step as chip designers is to establish a development environment that mimics industry standards. Most Electronic Design Automation (EDA) tools are native to Linux; therefore, we will use **Ubuntu (WSL2)** as our foundation. 

This log covers the installation of the core toolchain, the configuration of VS Code, and the implementation of our very first RTL module to ensure the engines are firing correctly.

---

### 🎯 Log Objectives
To get this environment ready, we will navigate through these stages:
* **Operating System:** Implementing Ubuntu/WSL2 as the Linux foundation.
* **The Toolchain:** Installing and configuring **Verilator**, **GTKWave**, and **Make**.
* **Project Structure:** Organizing files into standard RTL and Verification folders.
* **Editor & Version Control:** Connecting VS Code and initializing Git.
* **Hardware Verification:** Simulating an 8-bit counter to confirm the tools are working.

---

### 🛠️ The Foundation: Why Linux?
In the world of silicon engineering, Linux is the non-negotiable standard. By using **WSL2 (Windows Subsystem for Linux)**, we gain access to a full Linux kernel without needing to leave Windows.

#### 1. Installing WSL2
If you haven't set up your Linux subsystem yet, follow this quick guide:
> [🎥 How to install WSL2 (Credit: TechTime)](https://www.youtube.com/watch?v=eId6K8d0v6o)

#### 2. The Toolchain: Verilator, GTKWave, and Make
We use **Verilator** for high-performance RTL simulation, **GTKWave** for waveform analysis, and **Make** for build automation. 

Run this in your Ubuntu terminal:
```bash
sudo apt update && sudo apt install -y verilator gtkwave build-essential make
📂 Project Architecture
Professional RTL development requires a clean separation between design files and the verification environment.

Bash

mkdir -p galaxy_project/{rtl,dv,sim}
rtl/: Hardware design files (SystemVerilog).

dv/: Design Verification (Testbenches and C++ wrappers).

sim/: Temporary build files and simulation outputs.

✍️ The Editor: VS Code & Git
We use VS Code on Windows, but "tunnel" into Linux using the WSL Extension.

Essential Extensions
Once connected to WSL, install these inside the session:

Verilog-HDL/SystemVerilog: For syntax highlighting and linting.

C/C++ (Microsoft): Necessary for writing Verilator testbenches.

Version Control
To keep our repository clean, we must prevent Git from tracking compiled binaries. Initialize your repo and create a .gitignore:

<details> <summary><b>📄 Click to view my .gitignore configuration</b></summary>

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
To confirm the environment is fully functional, we will create a simple counter. We separate the "Clock Engine" (C++) from the "Hardware Logic" (SystemVerilog).

<details> <summary><b>📦 Step A: The Design (rtl/counter.sv)</b></summary>

Code snippet

module counter #( 
    parameter width = 8  
)(
    input logic clk,    
    input logic rst_n,  
    input logic en,     
    output logic [width-1:0] count  
);
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= '0;  
    end else if (en) begin
        count <= count + 1;  
    end
end
endmodule
</details>

<details> <summary><b>⚙️ Step B: The Clock Engine (dv/sim_main.cpp)</b></summary>

C++

#include "Vtb_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_top* top = new Vtb_top; 

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    int time = 0;
    while (!Verilated::gotFinish() && time < 1000) {
        top->clk = !top->clk; 
        top->eval();          
        tfp->dump(time);      
        time++;
    }

    tfp->close();
    delete top;
    return 0;
}
</details>

<details> <summary><b>🧪 Step C: The Testbench (dv/tb_counter.sv)</b></summary>

Code snippet

module tb_top ( 
  input logic clk,  
  output logic [7:0] count  
);
logic rst_n;
logic en;

counter #(.width(8)) u_counter (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .count(count)
);

initial begin
    rst_n = 0; en = 0;
    repeat (10) @(posedge clk);
    rst_n = 1;  
    repeat (5) @(posedge clk);
    en = 1;  
    repeat (50) @(posedge clk);
    $display ("done! counter value: %0d", count);
    $finish;
end
endmodule
</details>

<details> <summary><b>📜 Step D: The Automation (Makefile)</b></summary>

Makefile

VERILATOR = verilator
RTL_DIR = rtl
DV_DIR = dv
TOP_MODULE = tb_top

all: compile run

compile:
	$(VERILATOR) -Wall --trace --timing --cc \
		-I$(RTL_DIR) \
		$(DV_DIR)/$(TOP_MODULE).sv \
		--top-module $(TOP_MODULE) \
		--exe $(DV_DIR)/sim_main.cpp
	make -C obj_dir -f V$(TOP_MODULE).mk V$(TOP_MODULE)

run:
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir waveform.vcd
</details>

🔭 Running the Simulation
Compile & Run: Type make in your terminal.

View Waves: Type gtkwave waveform.vcd.

Analyze: Drag clk and count into the viewer to see the magic happen.

📝 Log 1 Summary
We have successfully established a professional development environment. By bridging Windows and Linux, we've moved past the "setup overhead" and are now officially ready to build hardware.

Key Accomplishments:

✅ Infrastructure: Deployed Ubuntu (WSL2).

✅ Toolchain: Installed Verilator, GTKWave, and Make.

✅ Hardware Baseline: Verified the flow with a modular 8-bit counter.

Junior's Note: It's tempting to just write code in a Windows editor and hope it works. Don't. Learning to navigate the Linux terminal and using a Makefile early on is what separates a "student" from a "junior engineer."
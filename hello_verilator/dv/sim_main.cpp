#include "Vtb_top.h"           /
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
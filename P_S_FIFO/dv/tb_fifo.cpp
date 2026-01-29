#include <iostream>
#include <memory>
#include "Vtb_fifo.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    // Create Verilator context
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    contextp->commandArgs(argc, argv);
    const std::unique_ptr<Vtb_fifo> top{new Vtb_fifo{contextp.get()}};

    // Waveform Setup
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("fifo_waveform.vcd");

    // Simulation Loop
    // This runs until the SystemVerilog code calls $finish
    while (!contextp->gotFinish()) {
    contextp->timeInc(1); // Advance 1 "unit" (which is 1ns thanks to your Makefile)
    top->eval();          // This triggers the internal 'always #5'
    tfp->dump(contextp->time());
    }

    // Cleanup and Close
    tfp->close();
    std::cout << "--- Simulation Finished ---" << std::endl;
    std::cout << "Waveform saved to: fifo_waveform.vcd" << std::endl;

    return 0;
}
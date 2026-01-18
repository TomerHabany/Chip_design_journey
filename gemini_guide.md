🌌 The Galaxy Project: SoC Implementation Roadmap
Objective: Bridge the theory-practice gap for graduates by building a functional System-on-Chip (SoC) through incremental RTL integration. Methodology: The "Log" system—each module must be designed, verified, and integrated into a growing hierarchy.

✅ Phase 1: Completed Foundations
Log 1-2: Foundational Logic: Established coding standards and synchronous design habits using arithmetic units and counters.

Log 3: Data Flow: Implemented a Synchronous FIFO to master handshaking and rate-matching between logic blocks.

Log 4a: UART Transmitter (TX):

Designed a 16x oversampling Baud Rate Generator.


Solved Synchronization Issue: Integrated a baude_en signal to prevent "1-clock-cycle" start bit errors by resetting the generator counter when in IDLE .
+1

Implemented a Registered Moore FSM for glitch-free serial transmission .

(current stage) write a top module and a TB to verify the design.

🚀 Phase 2:
Log 4b: UART Receiver (RX):

Implement falling-edge detection for Start-bit synchronization.

Design "Middle-of-bit" sampling logic (sampling at the 8th of 16 ticks) to ensure data integrity.

Add error checking (Framing errors).

Log 4c: Subsystem Loopback:

Connect TX and RX modules in a top-level wrapper.

Verify communication via a SystemVerilog Testbench using tasks to simulate data flow.

🏗️ Phase 3: System Integration (The SoC)
Log 5: The Bus Interface (APB Slave):

Wrap the UART and FIFO into an APB (Advanced Peripheral Bus) peripheral.

Implement Memory-Mapped I/O (MMIO) registers: TX_DATA, RX_DATA, STATUS, and BAUD_DIV.

Log 6: SoC Controller Integration:

Integrate a RISC-V Core (e.g., Ibex or PicoRV32) as the APB Master.

Connect the UART/FIFO APB Slave to the CPU's memory map.

Log 7: Software-Hardware Validation:

Write a "Hello World" C-driver to send strings from the CPU to a physical PC terminal via the UART hardware.

🛠️ Technical Context for AI Partners
Clocking: 100MHz System Clock.

Baud Rate: 115200 (16x oversampling).

Design Style: SystemVerilog, Registered Outputs, explicit always_ff and always_comb separation.

Handshaking: FIFO-based buffering between the Bus and the Serial interface.
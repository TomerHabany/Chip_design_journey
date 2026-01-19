# Toolchain variables
VERILATOR = verilator
# Updated paths to match your folder structure
RTL_DIR = rtl
DV_DIR = dv
TOP_MODULE = tb_top
V_BINARY = V$(TOP_MODULE)

# Default target: Compile and Run
all: compile run

compile:
	@echo "--- Step 1: Verilating and Building C++ Model ---"
	# --trace: enables waveform dumping
	# --timing: allows the use of @(posedge clk) in SystemVerilog
	# -I$(RTL_DIR): tells Verilator where to find counter.sv
	$(VERILATOR) -Wall --trace --timing --cc -I$(RTL_DIR) \
		$(DV_DIR)/$(TOP_MODULE).sv --top-module $(TOP_MODULE) \
		--exe $(DV_DIR)/sim_main.cpp
	
	@echo "--- Step 2: Compiling Binary via Make ---"
	# Build the executable from the translated C++ code
	make -C obj_dir -f $(V_BINARY).mk $(V_BINARY)

run:
	@echo "--- Step 3: Executing Simulation ---"
	# Run the binary generated in Step 2
	./obj_dir/$(V_BINARY)
	@echo "--- Simulation Complete. Waveform generated as waveform.vcd ---"

view:
	@echo "--- Opening GTKWave ---"
	gtkwave waveform.vcd

clean:
	@echo "--- Cleaning Workspace ---"
	rm -rf obj_dir waveform.vcd
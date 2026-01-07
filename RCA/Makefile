# --- Variables ---
VERILATOR = verilator
RTL_DIR = rtl
DV_DIR = dv
TOP_MODULE = tb_rca

# List all source files
# We include the RTL directory and the specific testbench
SRCS = $(RTL_DIR)/adder_1bit.sv $(RTL_DIR)/rca.sv $(DV_DIR)/$(TOP_MODULE).sv

# --- Build Rules ---
.PHONY: all compile run waves clean

all: clean compile run

compile:
	@echo "--- STEP 1 & 2: Verilating and Building Binary ---"
	$(VERILATOR) -Wall --trace --timing --binary \
		-I$(RTL_DIR) \
		$(SRCS) \
		--top-module $(TOP_MODULE) \
		-o V$(TOP_MODULE)

run:
	@echo "--- STEP 3: Running Simulation ---"
	./obj_dir/V$(TOP_MODULE)

waves:
	@echo "--- STEP 4: Opening Waveforms ---"
	gtkwave waveform.vcd

clean:
	@echo "Cleaning up project files..."
	rm -rf obj_dir waveform.vcd
	
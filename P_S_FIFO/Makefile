# Variables
VERILATOR = verilator
RTL_DIR = rtl
DV_DIR = dv
TOP_MODULE = tb_fifo

# List all source files
# Note: It's often cleaner to separate Verilog sources from the C++ wrapper
SV_SRCS = $(RTL_DIR)/fifo.sv $(DV_DIR)/tb_fifo.sv
CPP_SRCS = $(DV_DIR)/tb_fifo.cpp

# Build rules
.PHONY: all compile run waves clean

all: clean compile run

compile:
	@echo "--- STEP 1 & 2: Verilating and Building Binary ---"
	$(VERILATOR) -Wall --trace --timing -sv --cc --exe --build \
		-I$(RTL_DIR) -I$(DV_DIR) \
		$(SV_SRCS) $(CPP_SRCS) \
		--top-module $(TOP_MODULE) \
		-o V$(TOP_MODULE) \
		-Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM \
		-Wno-MODDUP -Wno-DECLFILENAME -Wno-INITIALDLY

run:
	@echo "--- STEP 3: Running Simulation ---"
	./obj_dir/V$(TOP_MODULE)

waves:
	@echo "--- STEP 4: Opening Waveforms ---"
	gtkwave fifo_waveform.vcd &

clean:
	@echo "Cleaning up project files..."
	rm -rf obj_dir fifo_waveform.vcd

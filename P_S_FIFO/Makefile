# Variables
VERILATOR = verilator
RTL_DIR = rtl
DV_DIR = dv
TOP_MODULE = tb_fifo

# List all source files
SRCS = $(RTL_DIR)/fifo.sv $(DV_DIR)/tb_fifo.sv $(DV_DIR)/tb_fifo.cpp

# Build rules
.PHONY: all compile run waves clean

all: clean compile run

compile:
	@echo "--- STEP 1 & 2: Verilating and Building Binary ---"
	$(VERILATOR) -Wall --trace --timing -sv --cc --exe --build \
		-I$(RTL_DIR) \
		$(SRCS) \
		--top-module $(TOP_MODULE) \
		-o V$(TOP_MODULE) \
		-Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM

run:
	@echo "--- STEP 3: Running Simulation ---"
	./obj_dir/V$(TOP_MODULE)

waves:
	@echo "--- STEP 4: Opening Waveforms ---"
	gtkwave fifo_waveform.vcd

clean:
	@echo "Cleaning up project files..."
	rm -rf obj_dir fifo_waveform.vcd
	
# Makefile para compilar y simular spi_mem en Questasim

# Variables
QUESTA_BIN ?= vsim
VLOG_FLAGS = -cover bcest
VSIM_FLAGS = -t ps -do "wave.do" -do "run -all" -coverage +UVM_TESTNAME=test -vopt +acc
TOP_MODULE = spi_mem_tb_top

# Carpetas
RTL_DIR = ../rtl
TB_DIR = ../tb

# Includes
INCLUDE_DIRS = \
	+incdir+./../misc \
	+incdir+./../UVM_TB_TOP_PKG \
	+incdir+./../UVM_SEQ_PKG \
	+incdir+./../TB/UVM_TESTS_PKG \
	+incdir+./../TB/UVM_SPI_PKG

# Archivos RTL
RTL_SRCS = \
	$(RTL_DIR)/spi_mem_intf.sv \
	$(RTL_DIR)/spi_mem.sv \
	$(RTL_DIR)/spi_mem_top.sv

# Archivos TB
TB_SRCS = \
	$(TB_DIR)/TB_TOP_FOLDER/spi_mem_data_types_pkg.svh \
	$(TB_DIR)/UVM_SPI_PKG/uvm_spi_mem_pkg.svh \
	$(TB_DIR)/UVM_TOP_PKG/uvm_spi_mem_tb_top_pkg.svh \
	$(TB_DIR)/UVM_SEQ_PKG/uvm_spi_mem_sequences_pkg.svh \
	$(TB_DIR)/UVM_TEST_PKG/uvm_spi_mem_tests_pkg.svh \
	$(TB_DIR)/TB_TOP_FOLDER/spi_mem_tb_pkg.svh \
	$(TB_DIR)/TB_TOP_FOLDER/spi_mem_tb_if.sv \
	$(TB_DIR)/TB_TOP_FOLDER/spi_mem_tb_top.sv

# Targets
all: compile simulate

compile:
	@echo "Creando librería work..."
	@vlib work
	@echo "Compilando RTL..."
	@for file in $(RTL_SRCS); do \
		vlog $(VLOG_FLAGS) $(INCLUDE_DIRS) $$file || exit 1; \
	done
	@echo "Compilando Testbench..."
	@for file in $(TB_SRCS); do \
		vlog $(VLOG_FLAGS) $(INCLUDE_DIRS) $$file || exit 1; \
	done

simulate:
	@echo "Simulando..."
	$(QUESTA_BIN) $(VSIM_FLAGS) $(TOP_MODULE)

clean:
	rm -rf work transcript vsim.wlf *.log *.ucdb

.PHONY: all compile simulate clean

#######################################################################################
#
# This is the compilation file for the Soft Error Tolerant GPIO RTL and its testbench
#
#######################################################################################

# RTL files for compilation
vlog -cover bcest ../rtl/spi_mem_intf.sv
vlog -cover bcest ../rtl/spi_mem.sv
vlog -cover bcest ../rtl/spi_mem_top.sv

#######################################################################################

# TB files for compilation

vlog ../tb/TB_TOP_FOLDER/spi_mem_data_types_pkg.svh
vlog ../tb/UVM_SPI_PKG/uvm_spi_mem_pkg.svh +incdir+./../TB/UVM_SPI_PKG
#vlog ../tb/UVM_REF_MODEL/uvm_spi_mem_ref_model_pkg.svh +incdir+./../UVM_REF_MODEL
vlog ../tb/UVM_TOP_PKG/uvm_spi_mem_tb_top_pkg.svh +incdir+./../mics +incdir+./../UVM_TB_TOP_PKG                    

#########################################################################################

vlog ../tb/UVM_SEQ_PKG/uvm_spi_mem_sequences_pkg.svh +incdir+./../misc +incdir+./../UVM_SEQ_PKG
vlog ../tb/UVM_TEST_PKG/uvm_spi_mem_tests_pkg.svh +incdir+./../TB/UVM_TESTS_PKG
vlog ../tb/TB_TOP_FOLDER/spi_mem_tb_pkg.svh
vlog ../tb/TB_TOP_FOLDER/spi_mem_tb_if.sv +incdir+./../misc
#vlog ../tb/TB_TOP_FOLDER/spi_mem_assertions.sv +incdir+./../misc
vlog ../tb/TB_TOP_FOLDER/spi_mem_tb_top.sv +incdir+./../misc


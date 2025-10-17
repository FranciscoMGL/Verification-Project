/////////////////////////////////////////////////////////////////
//
// Ejercicio: Verificación de SPI-MEM (spi_mem_top.sv)
// UVM - spi_mem_mon.sv
// Monitor 
//
///////////////////////////////////////////////////////////////////

 module spi_mem_tb_top;

   import uvm_pkg::*;
   import spi_mem_tb_pkg::*;
  
  
   spi_i vif();
  
   spi_mem_top dut (.wr(vif.wr), .clk(vif.clk), .rst(vif.rst), .addr(vif.addr), .din(vif.din), .dout(vif.dout), .done(vif.done), .err(vif.err));
  
   initial begin
    vif.clk <= 0;
   end
 
   always #10 vif.clk <= ~vif.clk;
 
  
  
   initial begin
     uvm_config_db#(virtual spi_i)::set(null, "*", "vif", vif);
     run_test("");
   end
  
 
  
endmodule
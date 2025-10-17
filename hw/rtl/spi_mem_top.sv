/////////////////////////////////////////////////////////////////
//
// Ejercicio: Verificación de SPI-MEM (spi_mem_top.sv)
// UVM - spi_mem_top.sv
// SPI MEM Top Module
//
/////////////////////////////////////////////////////////////////// 
 
 module spi_mem_top(
     input wr,clk,rst,
     input [7:0] addr, din,
     output [7:0] dout,
     output done, err
     );
  
  wire csreg, mosireg, misoreg, readyreg, opdonereg;
 
  spi_mem_intf intf (wr, clk, rst, readyreg, opdonereg, addr, din, dout, csreg, mosireg, misoreg, done, err);
  spi_mem  mem_inst (clk, rst, csreg, mosireg, readyreg, misoreg, opdonereg);
 
 endmodule
 
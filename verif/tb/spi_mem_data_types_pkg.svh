/////////////////////////////////////////////////////////////////
//
// Ejercicio: Verificación de SPI-MEM
// UVM - spi_mem_datatypes.sv
// Data Types 
//
///////////////////////////////////////////////////////////////////

  package spi_mem_data_types_pkg;

  typedef enum bit [2:0]   {readd = 0, writed = 1, rstdut = 2, writeerr = 3, readerr = 4} oper_mode;

  endpackage
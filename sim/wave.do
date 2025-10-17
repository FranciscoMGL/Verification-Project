onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /spi_mem_tb_top/dut/clk
add wave -noupdate /spi_mem_tb_top/dut/rst
add wave -noupdate /spi_mem_tb_top/dut/wr
add wave -noupdate /spi_mem_tb_top/dut/addr
add wave -noupdate /spi_mem_tb_top/dut/din
add wave -noupdate /spi_mem_tb_top/dut/dout
add wave -noupdate /spi_mem_tb_top/dut/done
add wave -noupdate /spi_mem_tb_top/dut/err
add wave -noupdate /spi_mem_tb_top/dut/csreg
add wave -noupdate /spi_mem_tb_top/dut/mosireg
add wave -noupdate /spi_mem_tb_top/dut/misoreg
add wave -noupdate /spi_mem_tb_top/dut/readyreg
add wave -noupdate /spi_mem_tb_top/dut/opdonereg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2948 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {3210 ps}

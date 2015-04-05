include ../Makefile.inc

fpga_dir=../../..
rtl_dir=$(fpga_dir)/orpsocv2/rtl/verilog
board_rtl_dir=$(fpga_dir)/orpsocv2/boards/xilinx/atlys/rtl/verilog

includes=\
	-I../ \
	-y$(rtl_dir)/ram_wb \
	-y../

default:
	$(Q)iverilog -o bench $(includes) ../bench.v
	./bench

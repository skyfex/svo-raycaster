
Q=@

rtl_dir=../orpsoc/rtl/verilog
board_rtl_dir=../orpsoc/boards/xilinx/atlys/rtl/verilog

includes=\
	-I$(board_rtl_dir)/include \
	-Ibenches \
	-y$(board_rtl_dir)/arbiter \
	-y$(rtl_dir)/ram_wb \
	-y$(board_rtl_dir)/raycaster \
	-ybenches

default:
	$(Q)iverilog -o outputs/bench $(includes) benches/bench.v
	cd outputs && ./bench
	make vmem_extract
	
debug:
	$(Q)iverilog -pfileline=1 -o outputs/bench $(includes) benches/bench.v
	cd outputs && ./bench

core:
	$(Q)iverilog -o outputs/bench_core $(includes) benches/bench_core.v
	cd outputs && ./bench_core

test:
	$(Q)iverilog -o outputs/test $(includes) benches/test.v
	cd outputs && ./test

vmem:
	gcc -o misc/build_vmem misc/common.c misc/build_vmem.c
	cd misc && ./build_vmem
	cp misc/sram.vmem outputs/sram.vmem
	cp misc/sim_params.v benches/sim_params.v
	rm misc/build_vmem misc/sram.vmem misc/sim_params.v

vmem_extract:
	cd outputs && ./vmem_to_bin.py
	open outputs/out.png

setup_atlys:
	gcc -lfpgalink -o misc/setup_atlys misc/common.c misc/setup_atlys.c
	cd misc && ./setup_atlys
	
extract:
	gcc -lfpgalink -o misc/extract_image misc/common.c misc/extract_image.c
	cd misc && ./extract_image
	cd misc && open out.bmp

orpsoc:	
	orlink program ~/FPGA/orpsoc/boards/xilinx/atlys/backend/par/run/orpsoc.xsvf

gpio:
	orlink upload ~/FPGA/orpsocv2/boards/xilinx/atlys/sw/apps/gpio/gpio.bin 0
	
vga:
	orlink upload ~/FPGA/orpsocv2/boards/xilinx/atlys/sw/apps/test/test.bin 0	
	
all: orpsoc gpio setup_atlys
	

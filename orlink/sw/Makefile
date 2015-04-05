
FLAGS=-O3 -Wall -Wextra -Wundef -pedantic-errors -std=c99 -Wstrict-prototypes -Wno-missing-field-initializers
SOURCES=orlink.c
INCLUDES=-I./fpgalink
LIBRARIES=-lfpgalink
default: $(SOURCES)
	gcc  $(FLAGS) -Wl,-rpath,@loader_path/ $(INCLUDES) $(LIBRARIES) -o orlink $(SOURCES)
  
program:
	./orlink program ../hw/run/orlink.xsvf
	
minisoc:
	./orlink program ~/FPGA/minisoc/run/minisoc.xsvf

test: default
	./orlink test
	
orpsoc:
	./orlink program ~/FPGA/orpsocv2/boards/xilinx/atlys/backend/par/run/orpsoc.xsvf
	
gpio:
	./orlink upload ../../orpsocv2/boards/xilinx/atlys/sw/apps/gpio/gpio.bin
	
install: default
	cp orlink /usr/local/bin/orlink
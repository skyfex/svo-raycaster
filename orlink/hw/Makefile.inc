ifeq ($(V), 1)
Q=
QUIET=
else
Q ?=@
QUIET=-quiet
endif

CUR_DIR=$(shell pwd)
PRJ_ROOT ?=$(CUR_DIR)/..

fpga_dir=../../..
RTL_DIR=$(fpga_dir)/orpsoc/rtl/verilog
BOARD_RTL_DIR=$(fpga_dir)/orpsoc/boards/xilinx/atlys/rtl/verilog

FPGA_VENDOR=xilinx
FPGA_ARCH=spartan6
BOARD_NAME=atlys
BOARD=$(FPGA_VENDOR)/$(BOARD_NAME)
DESIGN_NAME=orlink

FPGA_PART ?=xc6slx45-2-csg324
OPT_MODE ?=Speed
OPT_LEVEL ?=2

RTL_VERILOG_SRC=$(PRJ_ROOT)/orlink.v $(PRJ_ROOT)/orlink_top.v $(RTL_DIR)/ram_wb/ram_wb.v $(RTL_DIR)/ram_wb/ram_wb_b3.v $(PRJ_ROOT)/ngc/orlink_ltw_fifo.v $(PRJ_ROOT)/ngc/orlink_wtl_fifo.v
RTL_TOP=orlink_top


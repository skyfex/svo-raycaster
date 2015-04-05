include ../Makefile.inc

# NGC_FILE=$(DESIGN_NAME).ngc
NGD_FILE=$(DESIGN_NAME).ngd
UCF_FILE=$(PRJ_ROOT)/$(DESIGN_NAME).ucf
MAPPED_NCD=$(DESIGN_NAME)_mapped.ncd
PARRED_NCD=$(DESIGN_NAME).ncd
PCF_FILE=$(DESIGN_NAME).pcf
BIT_FILE=$(DESIGN_NAME).bit
BIT_FILE_FOR_SPI=$(DESIGN_NAME)_spiboot.bit
BATCH_FILE=$(DESIGN_NAME).batch
BATCH_XSVF_FILE=$(DESIGN_NAME)_xsvf.batch
XSVF_FILE=$(DESIGN_NAME).xsvf
MCS_FILE=$(DESIGN_NAME).mcs

BOARD_BACKEND_BIN_DIR=$(PRJ_ROOT)/ngc

ifeq ($(V), 1)
XILINX_FLAGS ?=
else
XILINX_FLAGS ?=-intstyle silent
endif
XILINX_MAP_FLAGS=-logic_opt off
XILINX_AREA_TARGET = speed
TIMING_REPORT_OPTIONS = -u 1000 -e 1000
SPI_FLASH_SIZE_KBYTES ?=16384
SPI_BOOTLOADER_SW_OFFSET_HEX ?=1c0000

$(NGD_FILE): $(UCF_FILE) $(NGC_FILE)
	@echo; echo "\t#### Running NGDBuild ####";
	$(Q)ngdbuild -p $(FPGA_PART) -sd $(BOARD_BACKEND_BIN_DIR) \
	-uc $(UCF_FILE)	$(NGC_FILE) $@

#This target uses Xilinx tools to perform Mapping
$(MAPPED_NCD): $(NGD_FILE)
	@echo; echo "\t#### Mapping ####";
	$(Q)map -p $(FPGA_PART) -detail -pr b \
	-timing -ol high -w $(XILINX_FLAGS) -o $@ -xe n $(NGD_FILE) $(PCF_FILE)
	
#This target uses Xilinx tools to Place & Route the design
$(PARRED_NCD): $(MAPPED_NCD)
	@echo; echo "\t#### PAR'ing ####";
	$(Q)par -w -ol high -xe n $(XILINX_FLAGS) $< $@ $(PCF_FILE)
	
#This target uses Xilinx tools to generate a bitstream for download
$(BIT_FILE): $(PARRED_NCD)
	@echo; echo "\t#### Generating .bit file ####";
	#$(Q)bitgen -w $(XILINX_FLAGS) -g StartUpClk:CClk $< $@
	$(Q)bitgen -w $(XILINX_FLAGS) -g StartUpClk:JtagClk $< $@

$(BIT_FILE_FOR_SPI): $(PARRED_NCD)
	@echo; echo "\t#### Generating .bit file for SPI load ####";
	$(Q)bitgen -w $(XILINX_FLAGS) -g StartUpClk:CClk $< $@
	
$(MCS_FILE): $(BIT_FILE_FOR_SPI)
	@echo; echo "\t#### Generating .mcs file for SPI load ####";
	$(Q)promgen -spi -p mcs -w -o $@ -s $(SPI_FLASH_SIZE_KBYTES) -u 0 $<
	
	
$(BATCH_FILE):
	$(Q)echo "setMode -bs" >> $@
	$(Q)echo "addDevice -p 1 -file \""$(BIT_FILE)"\"" >> $@
	$(Q)echo "setCable -p auto" >> $@
	$(Q)echo "program -p 1" >> $@
	$(Q)echo "quit" >> $@
	
$(BATCH_XSVF_FILE): $(BIT_FILE)
	$(Q)echo "setMode -bs" >> $@
	$(Q)echo "addDevice -p 1 -file \""$(BIT_FILE)"\"" >> $@
	$(Q)echo "setCable -port xsvf -file \""$(XSVF_FILE)"\"" >> $@
	$(Q)echo "program -p 1" >> $@
	$(Q)echo "quit" >> $@	

$(XSVF_FILE): $(BATCH_XSVF_FILE)
	impact -batch $(BATCH_XSVF_FILE)
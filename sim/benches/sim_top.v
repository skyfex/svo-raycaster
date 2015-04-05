
`include "orpsoc-defines.v"

module sim_top
	(
	input wb_clk,
	input wb_rst,
	
	input [31:0]		wb_adr_o,
	input [3:0]			wb_sel_o,
	input [31:0]		wb_dat_o,
	input					wb_we_o,
	input					wb_cyc_o,
	input					wb_stb_o,
	input [2:0]			wb_cti_o,
	input [1:0]			wb_bte_o,
	output [31:0]		wb_dat_i,
	output				wb_ack_i,
	output				wb_err_i,
	output				wb_rty_i
	);
	
	`include "orpsoc-params.v"	  
	`include "sim_params.v"	  

	// = Bus Wires =


  wire [wb_aw-1:0] 	      wbm_i_or12_adr_o;
   wire [wb_dw-1:0] 	      wbm_i_or12_dat_o;
   wire [3:0] 		      wbm_i_or12_sel_o;
   wire 		      wbm_i_or12_we_o;
   wire 		      wbm_i_or12_cyc_o;
   wire 		      wbm_i_or12_stb_o;
   wire [2:0] 		      wbm_i_or12_cti_o;
   wire [1:0] 		      wbm_i_or12_bte_o;

   wire [wb_dw-1:0] 	      wbm_i_or12_dat_i;   
   wire 		      wbm_i_or12_ack_i;
   wire 		      wbm_i_or12_err_i;
   wire 		      wbm_i_or12_rty_i;

   // OR1200 data bus wires   
   wire [wb_aw-1:0] 	      wbm_d_or12_adr_o;
   wire [wb_dw-1:0] 	      wbm_d_or12_dat_o;
   wire [3:0] 		      wbm_d_or12_sel_o;
   wire 		      wbm_d_or12_we_o;
   wire 		      wbm_d_or12_cyc_o;
   wire 		      wbm_d_or12_stb_o;
   wire [2:0] 		      wbm_d_or12_cti_o;
   wire [1:0] 		      wbm_d_or12_bte_o;

   wire [wb_dw-1:0] 	      wbm_d_or12_dat_i;   
   wire 		      wbm_d_or12_ack_i;
   wire 		      wbm_d_or12_err_i;
   wire 		      wbm_d_or12_rty_i;   

   // Debug interface bus wires   
   wire [wb_aw-1:0] 	      wbm_d_dbg_adr_o;
   wire [wb_dw-1:0] 	      wbm_d_dbg_dat_o;
   wire [3:0] 		      wbm_d_dbg_sel_o;
   wire 		      wbm_d_dbg_we_o;
   wire 		      wbm_d_dbg_cyc_o;
   wire 		      wbm_d_dbg_stb_o;
   wire [2:0] 		      wbm_d_dbg_cti_o;
   wire [1:0] 		      wbm_d_dbg_bte_o;

   wire [wb_dw-1:0] 	      wbm_d_dbg_dat_i;   
   wire 		      wbm_d_dbg_ack_i;
   wire 		      wbm_d_dbg_err_i;
   wire 		      wbm_d_dbg_rty_i;

   // Byte bus bridge master signals
   wire [wb_aw-1:0] 	      wbm_b_d_adr_o;
   wire [wb_dw-1:0] 	      wbm_b_d_dat_o;
   wire [3:0] 		      wbm_b_d_sel_o;
   wire 		      wbm_b_d_we_o;
   wire 		      wbm_b_d_cyc_o;
   wire 		      wbm_b_d_stb_o;
   wire [2:0] 		      wbm_b_d_cti_o;
   wire [1:0] 		      wbm_b_d_bte_o;

   wire [wb_dw-1:0] 	      wbm_b_d_dat_i;   
   wire 		      wbm_b_d_ack_i;
   wire 		      wbm_b_d_err_i;
   wire 		      wbm_b_d_rty_i;   

   // Instruction bus slave wires //

   // rom0 instruction bus wires
   wire [31:0] 		      wbs_i_rom0_adr_i;
   wire [wbs_i_rom0_data_width-1:0] wbs_i_rom0_dat_i;
   wire [3:0] 			    wbs_i_rom0_sel_i;
   wire 			    wbs_i_rom0_we_i;
   wire 			    wbs_i_rom0_cyc_i;
   wire 			    wbs_i_rom0_stb_i;
   wire [2:0] 			    wbs_i_rom0_cti_i;
   wire [1:0] 			    wbs_i_rom0_bte_i;   
   wire [wbs_i_rom0_data_width-1:0] wbs_i_rom0_dat_o;   
   wire 			    wbs_i_rom0_ack_o;
   wire 			    wbs_i_rom0_err_o;
   wire 			    wbs_i_rom0_rty_o;   

   // mc0 instruction bus wires
   wire [31:0] 			    wbs_i_mc0_adr_i;
   wire [wbs_i_mc0_data_width-1:0]  wbs_i_mc0_dat_i;
   wire [3:0] 			    wbs_i_mc0_sel_i;
   wire 			    wbs_i_mc0_we_i;
   wire 			    wbs_i_mc0_cyc_i;
   wire 			    wbs_i_mc0_stb_i;
   wire [2:0] 			    wbs_i_mc0_cti_i;
   wire [1:0] 			    wbs_i_mc0_bte_i;   
   wire [wbs_i_mc0_data_width-1:0]  wbs_i_mc0_dat_o;   
   wire 			    wbs_i_mc0_ack_o;
   wire 			    wbs_i_mc0_err_o;
   wire 			    wbs_i_mc0_rty_o;   

   // Data bus slave wires //

   // mc0 data bus wires
   wire [31:0] 			    wbs_d_mc0_adr_i;
   wire [wbs_d_mc0_data_width-1:0]  wbs_d_mc0_dat_i;
   wire [3:0] 			    wbs_d_mc0_sel_i;
   wire 			    wbs_d_mc0_we_i;
   wire 			    wbs_d_mc0_cyc_i;
   wire 			    wbs_d_mc0_stb_i;
   wire [2:0] 			    wbs_d_mc0_cti_i;
   wire [1:0] 			    wbs_d_mc0_bte_i;   
   wire [wbs_d_mc0_data_width-1:0]  wbs_d_mc0_dat_o;   
   wire 			    wbs_d_mc0_ack_o;
   wire 			    wbs_d_mc0_err_o;
   wire 			    wbs_d_mc0_rty_o;

   // i2c0 wires
   wire [31:0] 			    wbs_d_i2c0_adr_i;
   wire [wbs_d_i2c0_data_width-1:0] wbs_d_i2c0_dat_i;
   wire [3:0] 			    wbs_d_i2c0_sel_i;
   wire 			    wbs_d_i2c0_we_i;
   wire 			    wbs_d_i2c0_cyc_i;
   wire 			    wbs_d_i2c0_stb_i;
   wire [2:0] 			    wbs_d_i2c0_cti_i;
   wire [1:0] 			    wbs_d_i2c0_bte_i;   
   wire [wbs_d_i2c0_data_width-1:0] wbs_d_i2c0_dat_o;   
   wire 			    wbs_d_i2c0_ack_o;
   wire 			    wbs_d_i2c0_err_o;
   wire 			    wbs_d_i2c0_rty_o;   

   // i2c1 wires
   wire [31:0] 			    wbs_d_i2c1_adr_i;
   wire [wbs_d_i2c1_data_width-1:0] wbs_d_i2c1_dat_i;
   wire [3:0] 			    wbs_d_i2c1_sel_i;
   wire 			    wbs_d_i2c1_we_i;
   wire 			    wbs_d_i2c1_cyc_i;
   wire 			    wbs_d_i2c1_stb_i;
   wire [2:0] 			    wbs_d_i2c1_cti_i;
   wire [1:0] 			    wbs_d_i2c1_bte_i;   
   wire [wbs_d_i2c1_data_width-1:0] wbs_d_i2c1_dat_o;   
   wire 			    wbs_d_i2c1_ack_o;
   wire 			    wbs_d_i2c1_err_o;
   wire 			    wbs_d_i2c1_rty_o;

   // spi0 wires
   wire [31:0] 			    wbs_d_spi0_adr_i;
   wire [wbs_d_spi0_data_width-1:0] wbs_d_spi0_dat_i;
   wire [3:0] 			    wbs_d_spi0_sel_i;
   wire 			    wbs_d_spi0_we_i;
   wire 			    wbs_d_spi0_cyc_i;
   wire 			    wbs_d_spi0_stb_i;
   wire [2:0] 			    wbs_d_spi0_cti_i;
   wire [1:0] 			    wbs_d_spi0_bte_i;   
   wire [wbs_d_spi0_data_width-1:0] wbs_d_spi0_dat_o;   
   wire 			    wbs_d_spi0_ack_o;
   wire 			    wbs_d_spi0_err_o;
   wire 			    wbs_d_spi0_rty_o;   

   // uart0 wires
   wire [31:0] 			     wbs_d_uart0_adr_i;
   wire [wbs_d_uart0_data_width-1:0] wbs_d_uart0_dat_i;
   wire [3:0] 			     wbs_d_uart0_sel_i;
   wire 			     wbs_d_uart0_we_i;
   wire 			     wbs_d_uart0_cyc_i;
   wire 			     wbs_d_uart0_stb_i;
   wire [2:0] 			     wbs_d_uart0_cti_i;
   wire [1:0] 			     wbs_d_uart0_bte_i;   
   wire [wbs_d_uart0_data_width-1:0] wbs_d_uart0_dat_o;   
   wire 			     wbs_d_uart0_ack_o;
   wire 			     wbs_d_uart0_err_o;
   wire 			     wbs_d_uart0_rty_o;   

   // gpio0 wires
   wire [31:0] 			     wbs_d_gpio0_adr_i;
   wire [wbs_d_gpio0_data_width-1:0] wbs_d_gpio0_dat_i;
   wire [3:0] 			     wbs_d_gpio0_sel_i;
   wire 			     wbs_d_gpio0_we_i;
   wire 			     wbs_d_gpio0_cyc_i;
   wire 			     wbs_d_gpio0_stb_i;
   wire [2:0] 			     wbs_d_gpio0_cti_i;
   wire [1:0] 			     wbs_d_gpio0_bte_i;   
   wire [wbs_d_gpio0_data_width-1:0] wbs_d_gpio0_dat_o;   
   wire 			     wbs_d_gpio0_ack_o;
   wire 			     wbs_d_gpio0_err_o;
   wire 			     wbs_d_gpio0_rty_o;

   // ps2_0 wires
   wire [31:0]               wbs_d_ps2_0_adr_i;
   wire [wbs_d_ps2_0_data_width-1:0] wbs_d_ps2_0_dat_i;
   wire [3:0]                wbs_d_ps2_0_sel_i;
   wire                  wbs_d_ps2_0_we_i;
   wire                  wbs_d_ps2_0_cyc_i;
   wire                  wbs_d_ps2_0_stb_i;
   wire [2:0]                wbs_d_ps2_0_cti_i;
   wire [1:0]                wbs_d_ps2_0_bte_i;   
   wire [wbs_d_ps2_0_data_width-1:0] wbs_d_ps2_0_dat_o;   
   wire                  wbs_d_ps2_0_ack_o;
   wire                  wbs_d_ps2_0_err_o;
   wire                  wbs_d_ps2_0_rty_o;

   // ps2_1 wires
   wire [31:0]               wbs_d_ps2_1_adr_i;
   wire [wbs_d_ps2_1_data_width-1:0] wbs_d_ps2_1_dat_i;
   wire [3:0]                wbs_d_ps2_1_sel_i;
   wire                  wbs_d_ps2_1_we_i;
   wire                  wbs_d_ps2_1_cyc_i;
   wire                  wbs_d_ps2_1_stb_i;
   wire [2:0]                wbs_d_ps2_1_cti_i;
   wire [1:0]                wbs_d_ps2_1_bte_i;   
   wire [wbs_d_ps2_1_data_width-1:0] wbs_d_ps2_1_dat_o;   
   wire                  wbs_d_ps2_1_ack_o;
   wire                  wbs_d_ps2_1_err_o;
   wire                  wbs_d_ps2_1_rty_o;

   // eth0 slave wires
   wire [31:0] 				  wbs_d_eth0_adr_i;
   wire [wbs_d_eth0_data_width-1:0] 	  wbs_d_eth0_dat_i;
   wire [3:0] 				  wbs_d_eth0_sel_i;
   wire 				  wbs_d_eth0_we_i;
   wire 				  wbs_d_eth0_cyc_i;
   wire 				  wbs_d_eth0_stb_i;
   wire [2:0] 				  wbs_d_eth0_cti_i;
   wire [1:0] 				  wbs_d_eth0_bte_i;   
   wire [wbs_d_eth0_data_width-1:0] 	  wbs_d_eth0_dat_o;   
   wire 				  wbs_d_eth0_ack_o;
   wire 				  wbs_d_eth0_err_o;
   wire 				  wbs_d_eth0_rty_o;

   // eth0 master wires
   wire [wbm_eth0_addr_width-1:0] 	  wbm_eth0_adr_o;
   wire [wbm_eth0_data_width-1:0] 	  wbm_eth0_dat_o;
   wire [3:0] 				  wbm_eth0_sel_o;
   wire 				  wbm_eth0_we_o;
   wire 				  wbm_eth0_cyc_o;
   wire 				  wbm_eth0_stb_o;
   wire [2:0] 				  wbm_eth0_cti_o;
   wire [1:0] 				  wbm_eth0_bte_o;
   wire [wbm_eth0_data_width-1:0]         wbm_eth0_dat_i;
   wire 				  wbm_eth0_ack_i;
   wire 				  wbm_eth0_err_i;
   wire 				  wbm_eth0_rty_i;

   // vga0 slave wires
   wire [31:0]                      wbs_d_vga0_adr_i;
   wire [wbs_d_vga0_data_width-1:0] wbs_d_vga0_dat_i;
   wire [3:0]                       wbs_d_vga0_sel_i;
   wire                             wbs_d_vga0_we_i;
   wire                             wbs_d_vga0_cyc_i;
   wire                             wbs_d_vga0_stb_i;
   wire [2:0]                       wbs_d_vga0_cti_i;
   wire [1:0]                       wbs_d_vga0_bte_i;   
   wire [wbs_d_vga0_data_width-1:0] wbs_d_vga0_dat_o;   
   wire                             wbs_d_vga0_ack_o;
   wire                             wbs_d_vga0_err_o;
   wire                             wbs_d_vga0_rty_o;

   // vga0 master wires
   wire [wbm_vga0_addr_width-1:0] 	wbm_vga0_adr_o;
   wire [wbm_vga0_data_width-1:0] 	wbm_vga0_dat_o;
   wire [3:0]                       wbm_vga0_sel_o;
   wire                             wbm_vga0_we_o;
   wire                             wbm_vga0_cyc_o;
   wire                             wbm_vga0_stb_o;
   wire [2:0]                       wbm_vga0_cti_o;
   wire [1:0]                       wbm_vga0_bte_o;
   wire [wbm_vga0_data_width-1:0]   wbm_vga0_dat_i;
   wire                             wbm_vga0_ack_i;
   wire                             wbm_vga0_err_i;
   wire                             wbm_vga0_rty_i;

   // ac97 slave wires
   wire [31:0]                      wbs_d_ac97_adr_i;
   wire [wbs_d_ac97_data_width-1:0] wbs_d_ac97_dat_i;
   wire [3:0]                       wbs_d_ac97_sel_i;
   wire                             wbs_d_ac97_we_i;
   wire                             wbs_d_ac97_cyc_i;
   wire                             wbs_d_ac97_stb_i;
   wire [2:0]                       wbs_d_ac97_cti_i;
   wire [1:0]                       wbs_d_ac97_bte_i;   
   wire [wbs_d_ac97_data_width-1:0] wbs_d_ac97_dat_o;   
   wire                             wbs_d_ac97_ack_o;
   wire                             wbs_d_ac97_err_o;
   wire                             wbs_d_ac97_rty_o;

   // dma0 slave wires
   wire [31:0]                      wbs_d_dma0_adr_i;
   wire [wbs_d_dma0_data_width-1:0] wbs_d_dma0_dat_i;
   wire [3:0]                       wbs_d_dma0_sel_i;
   wire                             wbs_d_dma0_we_i;
   wire                             wbs_d_dma0_cyc_i;
   wire                             wbs_d_dma0_stb_i;
   wire [2:0]                       wbs_d_dma0_cti_i;
   wire [1:0]                       wbs_d_dma0_bte_i;   
   wire [wbs_d_dma0_data_width-1:0] wbs_d_dma0_dat_o;   
   wire                             wbs_d_dma0_ack_o;
   wire                             wbs_d_dma0_err_o;
   wire                             wbs_d_dma0_rty_o;

   // dma0 master wires
   wire [wbm_dma0_addr_width-1:0] 	wbm_dma0_adr_o;
   wire [wbm_dma0_data_width-1:0] 	wbm_dma0_dat_o;
   wire [3:0]                       wbm_dma0_sel_o;
   wire                             wbm_dma0_we_o;
   wire                             wbm_dma0_cyc_o;
   wire                             wbm_dma0_stb_o;
   wire [2:0]                       wbm_dma0_cti_o;
   wire [1:0]                       wbm_dma0_bte_o;
   wire [wbm_dma0_data_width-1:0]   wbm_dma0_dat_i;
   wire                             wbm_dma0_ack_i;
   wire                             wbm_dma0_err_i;
   wire                             wbm_dma0_rty_i;

   // fdt0 slave wires
   wire [31:0] 			    wbs_d_fdt0_adr_i;
   wire [wbs_d_fdt0_data_width-1:0] 	    wbs_d_fdt0_dat_i;
   wire [3:0] 				    wbs_d_fdt0_sel_i;
   wire 				    wbs_d_fdt0_we_i;
   wire 				    wbs_d_fdt0_cyc_i;
   wire 				    wbs_d_fdt0_stb_i;
   wire [2:0] 				    wbs_d_fdt0_cti_i;
   wire [1:0] 				    wbs_d_fdt0_bte_i;
   wire [wbs_d_fdt0_data_width-1:0] 	    wbs_d_fdt0_dat_o;
   wire 				    wbs_d_fdt0_ack_o;
   wire 				    wbs_d_fdt0_err_o;
   wire 				    wbs_d_fdt0_rty_o;

   // orlink master wires
   wire [wbm_orlink_addr_width-1:0] 	  wbm_orlink_adr_o;
   wire [wbm_orlink_data_width-1:0] 	  wbm_orlink_dat_o;
   wire [3:0] 				  wbm_orlink_sel_o;
   wire 				  wbm_orlink_we_o;
   wire 				  wbm_orlink_cyc_o;
   wire 				  wbm_orlink_stb_o;
   wire [2:0] 				  wbm_orlink_cti_o;
   wire [1:0] 				  wbm_orlink_bte_o;
   wire [wbm_orlink_data_width-1:0]         wbm_orlink_dat_i;
   wire 				  wbm_orlink_ack_i;
   wire 				  wbm_orlink_err_i;
   wire 				  wbm_orlink_rty_i;


   // rayc wires
   wire [31:0] 			    wbs_d_rayc_adr_i;
   wire [wbs_d_rayc_data_width-1:0] wbs_d_rayc_dat_i;
   wire [3:0] 			    wbs_d_rayc_sel_i;
   wire 			    wbs_d_rayc_we_i;
   wire 			    wbs_d_rayc_cyc_i;
   wire 			    wbs_d_rayc_stb_i;
   wire [2:0] 			    wbs_d_rayc_cti_i;
   wire [1:0] 			    wbs_d_rayc_bte_i;   
   wire [wbs_d_rayc_data_width-1:0] wbs_d_rayc_dat_o;   
   wire 			    wbs_d_rayc_ack_o;
   wire 			    wbs_d_rayc_err_o;
   wire 			    wbs_d_rayc_rty_o;

   // rayc master wires
   wire [wbm_rayc_addr_width-1:0] 	  wbm_rayc_adr_o;
   wire [wbm_rayc_data_width-1:0] 	  wbm_rayc_dat_o;
   wire [3:0] 				  wbm_rayc_sel_o;
   wire 				  wbm_rayc_we_o;
   wire 				  wbm_rayc_cyc_o;
   wire 				  wbm_rayc_stb_o;
   wire [2:0] 				  wbm_rayc_cti_o;
   wire [1:0] 				  wbm_rayc_bte_o;
   wire [wbm_rayc_data_width-1:0]         wbm_rayc_dat_i;
   wire 				  wbm_rayc_ack_i;
   wire 				  wbm_rayc_err_i;
   wire 				  wbm_rayc_rty_i;
	// --

	// = Bus Wire Assignment =
	// Hook up to testbench
	assign wbm_d_or12_adr_o = wb_adr_o;
	assign wbm_d_or12_dat_o = wb_dat_o;
	assign wbm_d_or12_sel_o = wb_sel_o;
	assign wbm_d_or12_we_o	= wb_we_o;
	assign wbm_d_or12_cyc_o = wb_cyc_o;
	assign wbm_d_or12_stb_o = wb_stb_o;
	assign wbm_d_or12_cti_o = wb_cti_o;
	assign wbm_d_or12_bte_o = wb_bte_o;
	assign wb_dat_i = wbm_d_or12_dat_i;	  
	assign wb_ack_i = wbm_d_or12_ack_i;
	assign wb_err_i = wbm_d_or12_err_i;
	assign wb_rty_i = wbm_d_or12_rty_i;
	
	assign wbm_d_dbg_adr_o = 0;
	assign wbm_d_dbg_dat_o = 0;
	assign wbm_d_dbg_sel_o = 0;
	assign wbm_d_dbg_we_o  = 0;
	assign wbm_d_dbg_cyc_o = 0;
	assign wbm_d_dbg_stb_o = 0;
	assign wbm_d_dbg_cti_o = 0;
	assign wbm_d_dbg_bte_o = 0;
	// --

	// = Wishbone data bus =
	
   arbiter_dbus arbiter_dbus0
     (
      // Master 0
      // Inputs to arbiter from master
      .wbm0_adr_o			(wbm_d_or12_adr_o),
      .wbm0_dat_o			(wbm_d_or12_dat_o),
      .wbm0_sel_o			(wbm_d_or12_sel_o),
      .wbm0_we_o			(wbm_d_or12_we_o),
      .wbm0_cyc_o			(wbm_d_or12_cyc_o),
      .wbm0_stb_o			(wbm_d_or12_stb_o),
      .wbm0_cti_o			(wbm_d_or12_cti_o),
      .wbm0_bte_o			(wbm_d_or12_bte_o),
      // Outputs to master from arbiter
      .wbm0_dat_i			(wbm_d_or12_dat_i),
      .wbm0_ack_i			(wbm_d_or12_ack_i),
      .wbm0_err_i			(wbm_d_or12_err_i),
      .wbm0_rty_i			(wbm_d_or12_rty_i),

      // Master 0
      // Inputs to arbiter from master
      .wbm1_adr_o			(wbm_d_dbg_adr_o),
      .wbm1_dat_o			(wbm_d_dbg_dat_o),
      .wbm1_we_o			(wbm_d_dbg_we_o),
      .wbm1_cyc_o			(wbm_d_dbg_cyc_o),
      .wbm1_sel_o			(wbm_d_dbg_sel_o),
      .wbm1_stb_o			(wbm_d_dbg_stb_o),
      .wbm1_cti_o			(wbm_d_dbg_cti_o),
      .wbm1_bte_o			(wbm_d_dbg_bte_o),
      // Outputs to master from arbiter      
      .wbm1_dat_i			(wbm_d_dbg_dat_i),
      .wbm1_ack_i			(wbm_d_dbg_ack_i),
      .wbm1_err_i			(wbm_d_dbg_err_i),
      .wbm1_rty_i			(wbm_d_dbg_rty_i),

      // Slaves
      
      .wbs0_adr_i			(wbs_d_mc0_adr_i),
      .wbs0_dat_i			(wbs_d_mc0_dat_i),
      .wbs0_sel_i			(wbs_d_mc0_sel_i),
      .wbs0_we_i			(wbs_d_mc0_we_i),
      .wbs0_cyc_i			(wbs_d_mc0_cyc_i),
      .wbs0_stb_i			(wbs_d_mc0_stb_i),
      .wbs0_cti_i			(wbs_d_mc0_cti_i),
      .wbs0_bte_i			(wbs_d_mc0_bte_i),
      .wbs0_dat_o			(wbs_d_mc0_dat_o),
      .wbs0_ack_o			(wbs_d_mc0_ack_o),
      .wbs0_err_o			(wbs_d_mc0_err_o),
      .wbs0_rty_o			(wbs_d_mc0_rty_o),

      .wbs1_adr_i			(wbs_d_eth0_adr_i),
      .wbs1_dat_i			(wbs_d_eth0_dat_i),
      .wbs1_sel_i			(wbs_d_eth0_sel_i),
      .wbs1_we_i			(wbs_d_eth0_we_i),
      .wbs1_cyc_i			(wbs_d_eth0_cyc_i),
      .wbs1_stb_i			(wbs_d_eth0_stb_i),
      .wbs1_cti_i			(wbs_d_eth0_cti_i),
      .wbs1_bte_i			(wbs_d_eth0_bte_i),
      .wbs1_dat_o			(wbs_d_eth0_dat_o),
      .wbs1_ack_o			(wbs_d_eth0_ack_o),
      .wbs1_err_o			(wbs_d_eth0_err_o),
      .wbs1_rty_o			(wbs_d_eth0_rty_o),
      
      .wbs2_adr_i			(wbm_b_d_adr_o),
      .wbs2_dat_i			(wbm_b_d_dat_o),
      .wbs2_sel_i			(wbm_b_d_sel_o),
      .wbs2_we_i			(wbm_b_d_we_o),
      .wbs2_cyc_i			(wbm_b_d_cyc_o),
      .wbs2_stb_i			(wbm_b_d_stb_o),
      .wbs2_cti_i			(wbm_b_d_cti_o),
      .wbs2_bte_i			(wbm_b_d_bte_o),
      .wbs2_dat_o			(wbm_b_d_dat_i),
      .wbs2_ack_o			(wbm_b_d_ack_i),
      .wbs2_err_o			(wbm_b_d_err_i),
      .wbs2_rty_o			(wbm_b_d_rty_i),

      .wbs3_adr_i           (wbs_d_vga0_adr_i),
      .wbs3_dat_i           (wbs_d_vga0_dat_i),
      .wbs3_sel_i           (wbs_d_vga0_sel_i),
      .wbs3_we_i            (wbs_d_vga0_we_i),
      .wbs3_cyc_i           (wbs_d_vga0_cyc_i),
      .wbs3_stb_i           (wbs_d_vga0_stb_i),
      .wbs3_cti_i           (wbs_d_vga0_cti_i),
      .wbs3_bte_i           (wbs_d_vga0_bte_i),
      .wbs3_dat_o           (wbs_d_vga0_dat_o),
      .wbs3_ack_o           (wbs_d_vga0_ack_o),
      .wbs3_err_o           (wbs_d_vga0_err_o),
      .wbs3_rty_o           (wbs_d_vga0_rty_o),

      .wbs4_adr_i           (wbs_d_ac97_adr_i),
      .wbs4_dat_i           (wbs_d_ac97_dat_i),
      .wbs4_sel_i           (wbs_d_ac97_sel_i),
      .wbs4_we_i            (wbs_d_ac97_we_i),
      .wbs4_cyc_i           (wbs_d_ac97_cyc_i),
      .wbs4_stb_i           (wbs_d_ac97_stb_i),
      .wbs4_cti_i           (wbs_d_ac97_cti_i),
      .wbs4_bte_i           (wbs_d_ac97_bte_i),
      .wbs4_dat_o           (wbs_d_ac97_dat_o),
      .wbs4_ack_o           (wbs_d_ac97_ack_o),
      .wbs4_err_o           (wbs_d_ac97_err_o),
      .wbs4_rty_o           (wbs_d_ac97_rty_o),

      .wbs5_adr_i           (wbs_d_dma0_adr_i),
      .wbs5_dat_i           (wbs_d_dma0_dat_i),
      .wbs5_sel_i           (wbs_d_dma0_sel_i),
      .wbs5_we_i            (wbs_d_dma0_we_i),
      .wbs5_cyc_i           (wbs_d_dma0_cyc_i),
      .wbs5_stb_i           (wbs_d_dma0_stb_i),
      .wbs5_cti_i           (wbs_d_dma0_cti_i),
      .wbs5_bte_i           (wbs_d_dma0_bte_i),
      .wbs5_dat_o           (wbs_d_dma0_dat_o),
      .wbs5_ack_o           (wbs_d_dma0_ack_o),
      .wbs5_err_o           (wbs_d_dma0_err_o),
      .wbs5_rty_o           (wbs_d_dma0_rty_o),

      .wbs6_adr_i           (wbs_d_fdt0_adr_i),
      .wbs6_dat_i           (wbs_d_fdt0_dat_i),
      .wbs6_sel_i           (wbs_d_fdt0_sel_i),
      .wbs6_we_i            (wbs_d_fdt0_we_i),
      .wbs6_cyc_i           (wbs_d_fdt0_cyc_i),
      .wbs6_stb_i           (wbs_d_fdt0_stb_i),
      .wbs6_cti_i           (wbs_d_fdt0_cti_i),
      .wbs6_bte_i           (wbs_d_fdt0_bte_i),
      .wbs6_dat_o           (wbs_d_fdt0_dat_o),
      .wbs6_ack_o           (wbs_d_fdt0_ack_o),
      .wbs6_err_o           (wbs_d_fdt0_err_o),
      .wbs6_rty_o           (wbs_d_fdt0_rty_o),

      // Clock, reset inputs
      .wb_clk			(wb_clk),
      .wb_rst			(wb_rst));

   // These settings are from top level params file
   defparam arbiter_dbus0.wb_addr_match_width = dbus_arb_wb_addr_match_width;
   defparam arbiter_dbus0.wb_num_slaves = dbus_arb_wb_num_slaves;
   defparam arbiter_dbus0.slave0_adr = dbus_arb_slave0_adr;
   defparam arbiter_dbus0.slave1_adr = dbus_arb_slave1_adr;
   defparam arbiter_dbus0.slave3_adr = dbus_arb_slave3_adr;
   defparam arbiter_dbus0.slave4_adr = dbus_arb_slave4_adr;
   defparam arbiter_dbus0.slave5_adr = dbus_arb_slave5_adr;
   defparam arbiter_dbus0.slave6_adr = dbus_arb_slave6_adr;
	// --
	
	// = Wishbone byte bus =
   arbiter_bytebus arbiter_bytebus0
     (

      // Master 0
      // Inputs to arbiter from master
      .wbm0_adr_o			(wbm_b_d_adr_o),
      .wbm0_dat_o			(wbm_b_d_dat_o),
      .wbm0_sel_o			(wbm_b_d_sel_o),
      .wbm0_we_o			(wbm_b_d_we_o),
      .wbm0_cyc_o			(wbm_b_d_cyc_o),
      .wbm0_stb_o			(wbm_b_d_stb_o),
      .wbm0_cti_o			(wbm_b_d_cti_o),
      .wbm0_bte_o			(wbm_b_d_bte_o),
      // Outputs to master from arbiter
      .wbm0_dat_i			(wbm_b_d_dat_i),
      .wbm0_ack_i			(wbm_b_d_ack_i),
      .wbm0_err_i			(wbm_b_d_err_i),
      .wbm0_rty_i			(wbm_b_d_rty_i),

      // Byte bus slaves
      
      .wbs0_adr_i			(wbs_d_uart0_adr_i),
      .wbs0_dat_i			(wbs_d_uart0_dat_i),
      .wbs0_we_i			(wbs_d_uart0_we_i),
      .wbs0_cyc_i			(wbs_d_uart0_cyc_i),
      .wbs0_stb_i			(wbs_d_uart0_stb_i),
      .wbs0_cti_i			(wbs_d_uart0_cti_i),
      .wbs0_bte_i			(wbs_d_uart0_bte_i),
      .wbs0_dat_o			(wbs_d_uart0_dat_o),
      .wbs0_ack_o			(wbs_d_uart0_ack_o),
      .wbs0_err_o			(wbs_d_uart0_err_o),
      .wbs0_rty_o			(wbs_d_uart0_rty_o),

      .wbs1_adr_i			(wbs_d_gpio0_adr_i),
      .wbs1_dat_i			(wbs_d_gpio0_dat_i),
      .wbs1_we_i			(wbs_d_gpio0_we_i),
      .wbs1_cyc_i			(wbs_d_gpio0_cyc_i),
      .wbs1_stb_i			(wbs_d_gpio0_stb_i),
      .wbs1_cti_i			(wbs_d_gpio0_cti_i),
      .wbs1_bte_i			(wbs_d_gpio0_bte_i),
      .wbs1_dat_o			(wbs_d_gpio0_dat_o),
      .wbs1_ack_o			(wbs_d_gpio0_ack_o),
      .wbs1_err_o			(wbs_d_gpio0_err_o),
      .wbs1_rty_o			(wbs_d_gpio0_rty_o),

      .wbs2_adr_i			(wbs_d_rayc_adr_i),
      .wbs2_dat_i			(wbs_d_rayc_dat_i),
      .wbs2_we_i			(wbs_d_rayc_we_i ), 
      .wbs2_cyc_i			(wbs_d_rayc_cyc_i),
      .wbs2_stb_i			(wbs_d_rayc_stb_i),
      .wbs2_cti_i			(wbs_d_rayc_cti_i),
      .wbs2_bte_i			(wbs_d_rayc_bte_i),
      .wbs2_dat_o			(wbs_d_rayc_dat_o),
      .wbs2_ack_o			(wbs_d_rayc_ack_o),
      .wbs2_err_o			(wbs_d_rayc_err_o),
      .wbs2_rty_o			(wbs_d_rayc_rty_o),

      .wbs3_adr_i			(wbs_d_i2c1_adr_i),
      .wbs3_dat_i			(wbs_d_i2c1_dat_i),
      .wbs3_we_i			(wbs_d_i2c1_we_i ), 
      .wbs3_cyc_i			(wbs_d_i2c1_cyc_i),
      .wbs3_stb_i			(wbs_d_i2c1_stb_i),
      .wbs3_cti_i			(wbs_d_i2c1_cti_i),
      .wbs3_bte_i			(wbs_d_i2c1_bte_i),
      .wbs3_dat_o			(wbs_d_i2c1_dat_o),
      .wbs3_ack_o			(wbs_d_i2c1_ack_o),
      .wbs3_err_o			(wbs_d_i2c1_err_o),
      .wbs3_rty_o			(wbs_d_i2c1_rty_o),

      .wbs4_adr_i			(wbs_d_spi0_adr_i),
      .wbs4_dat_i			(wbs_d_spi0_dat_i),
      .wbs4_we_i			(wbs_d_spi0_we_i ), 
      .wbs4_cyc_i			(wbs_d_spi0_cyc_i),
      .wbs4_stb_i			(wbs_d_spi0_stb_i),
      .wbs4_cti_i			(wbs_d_spi0_cti_i),
      .wbs4_bte_i			(wbs_d_spi0_bte_i),
      .wbs4_dat_o			(wbs_d_spi0_dat_o),
      .wbs4_ack_o			(wbs_d_spi0_ack_o),
      .wbs4_err_o			(wbs_d_spi0_err_o),
      .wbs4_rty_o			(wbs_d_spi0_rty_o),

      .wbs5_adr_i           (wbs_d_ps2_0_adr_i),
      .wbs5_dat_i           (wbs_d_ps2_0_dat_i),
      .wbs5_we_i            (wbs_d_ps2_0_we_i ), 
      .wbs5_cyc_i           (wbs_d_ps2_0_cyc_i),
      .wbs5_stb_i           (wbs_d_ps2_0_stb_i),
      .wbs5_cti_i           (wbs_d_ps2_0_cti_i),
      .wbs5_bte_i           (wbs_d_ps2_0_bte_i),
      .wbs5_dat_o           (wbs_d_ps2_0_dat_o),
      .wbs5_ack_o           (wbs_d_ps2_0_ack_o),
      .wbs5_err_o           (wbs_d_ps2_0_err_o),
      .wbs5_rty_o           (wbs_d_ps2_0_rty_o),

      .wbs6_adr_i           (wbs_d_ps2_1_adr_i),
      .wbs6_dat_i           (wbs_d_ps2_1_dat_i),
      .wbs6_we_i            (wbs_d_ps2_1_we_i ), 
      .wbs6_cyc_i           (wbs_d_ps2_1_cyc_i),
      .wbs6_stb_i           (wbs_d_ps2_1_stb_i),
      .wbs6_cti_i           (wbs_d_ps2_1_cti_i),
      .wbs6_bte_i           (wbs_d_ps2_1_bte_i),
      .wbs6_dat_o           (wbs_d_ps2_1_dat_o),
      .wbs6_ack_o           (wbs_d_ps2_1_ack_o),
      .wbs6_err_o           (wbs_d_ps2_1_err_o),
      .wbs6_rty_o           (wbs_d_ps2_1_rty_o),

      // Clock, reset inputs
      .wb_clk			(wb_clk),
      .wb_rst			(wb_rst));

   defparam arbiter_bytebus0.wb_addr_match_width = bbus_arb_wb_addr_match_width;
   defparam arbiter_bytebus0.wb_num_slaves = bbus_arb_wb_num_slaves;

   defparam arbiter_bytebus0.slave0_adr = bbus_arb_slave0_adr;
   defparam arbiter_bytebus0.slave1_adr = bbus_arb_slave1_adr;
   defparam arbiter_bytebus0.slave2_adr = bbus_arb_slave2_adr;
   defparam arbiter_bytebus0.slave3_adr = bbus_arb_slave3_adr;
   defparam arbiter_bytebus0.slave4_adr = bbus_arb_slave4_adr;
   defparam arbiter_bytebus0.slave5_adr = bbus_arb_slave5_adr;
   defparam arbiter_bytebus0.slave6_adr = bbus_arb_slave6_adr;

	// --

	// = RAM =
	ram_wb xilinx_ddr2_0
	  (
		.wbm0_adr_i								 (wbm_rayc_adr_o), 
		.wbm0_bte_i								 (wbm_rayc_bte_o), 
		.wbm0_cti_i								 (wbm_rayc_cti_o), 
		.wbm0_cyc_i								 (wbm_rayc_cyc_o), 
		.wbm0_dat_i								 (wbm_rayc_dat_o), 
		.wbm0_sel_i								 (wbm_rayc_sel_o),
		.wbm0_stb_i								 (wbm_rayc_stb_o), 
		.wbm0_we_i								 (wbm_rayc_we_o),
		.wbm0_ack_o								 (wbm_rayc_ack_i), 
		.wbm0_err_o								 (wbm_rayc_err_i), 
		.wbm0_rty_o								 (wbm_rayc_rty_i), 
		.wbm0_dat_o								 (wbm_rayc_dat_i),
	
		.wbm1_adr_i								 (wbs_d_mc0_adr_i), 
		.wbm1_bte_i								 (wbs_d_mc0_bte_i), 
		.wbm1_cti_i								 (wbs_d_mc0_cti_i), 
		.wbm1_cyc_i								 (wbs_d_mc0_cyc_i), 
		.wbm1_dat_i								 (wbs_d_mc0_dat_i), 
		.wbm1_sel_i								 (wbs_d_mc0_sel_i),
		.wbm1_stb_i								 (wbs_d_mc0_stb_i), 
		.wbm1_we_i								 (wbs_d_mc0_we_i),
		.wbm1_ack_o								 (wbs_d_mc0_ack_o), 
		.wbm1_err_o								 (wbs_d_mc0_err_o), 
		.wbm1_rty_o								 (wbs_d_mc0_rty_o),
		.wbm1_dat_o								 (wbs_d_mc0_dat_o),
	
		.wbm2_adr_i								 (wbs_i_mc0_adr_i), 
		.wbm2_bte_i								 (wbs_i_mc0_bte_i), 
		.wbm2_cti_i								 (wbs_i_mc0_cti_i), 
		.wbm2_cyc_i								 (wbs_i_mc0_cyc_i), 
		.wbm2_dat_i								 (wbs_i_mc0_dat_i), 
		.wbm2_sel_i								 (wbs_i_mc0_sel_i),
		.wbm2_stb_i								 (wbs_i_mc0_stb_i), 
		.wbm2_we_i								 (wbs_i_mc0_we_i),
		.wbm2_ack_o								 (wbs_i_mc0_ack_o), 
		.wbm2_err_o								 (wbs_i_mc0_err_o), 
		.wbm2_rty_o								 (wbs_i_mc0_rty_o), 
		.wbm2_dat_o								 (wbs_i_mc0_dat_o),

	
		.wb_clk_i									(wb_clk),
		.wb_rst_i									(wb_rst)
		);

	defparam xilinx_ddr2_0.mem_size_bytes = vmem_size;
	defparam xilinx_ddr2_0.mem_adr_width = vmem_size_log2;
	// --

	raycaster rayc
	  (
		// Wishbone slave interface
		.wb_adr_i				(wbs_d_rayc_adr_i[wbs_d_rayc_addr_width-1:0]),
		.wb_dat_i				(wbs_d_rayc_dat_i),
		.wb_we_i				(wbs_d_rayc_we_i),
		.wb_cyc_i				(wbs_d_rayc_cyc_i),
		.wb_stb_i				(wbs_d_rayc_stb_i),
		.wb_cti_i				(wbs_d_rayc_cti_i),
		.wb_bte_i				(wbs_d_rayc_bte_i),
		.wb_dat_o				(wbs_d_rayc_dat_o),
		.wb_ack_o				(wbs_d_rayc_ack_o),
		.wb_err_o				(wbs_d_rayc_err_o),
		.wb_rty_o				(wbs_d_rayc_rty_o),

		// Wishbone Master Interface
		.m_wb_adr_o (wbm_rayc_adr_o[31:0]),
		.m_wb_sel_o (wbm_rayc_sel_o[3:0]),
		.m_wb_we_o	(wbm_rayc_we_o),
		.m_wb_dat_o (wbm_rayc_dat_o[31:0]),
		.m_wb_cyc_o (wbm_rayc_cyc_o),
		.m_wb_stb_o (wbm_rayc_stb_o),
		.m_wb_cti_o (wbm_rayc_cti_o[2:0]),
		.m_wb_bte_o (wbm_rayc_bte_o[1:0]),
		.m_wb_dat_i (wbm_rayc_dat_i[31:0]),
		.m_wb_ack_i (wbm_rayc_ack_i),
		.m_wb_err_i (wbm_rayc_err_i),

		.wb_clk				(wb_clk),
		.wb_rst				(wb_rst)
		);

	
endmodule
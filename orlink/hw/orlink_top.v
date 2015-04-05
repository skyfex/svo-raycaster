
/*`include "defines.v"*/
`define BUS_WIRES

module orlink_top
	(
		input rst_n,
		input sys_clk,
		
		input ifclk_in,
		inout [7:0] fifoData_io,
		input gotData_in,
		input gotRoom_in,

		output sloe_out,     
		output slrd_out,    
		output slwr_out,   
		output [1:0] fifoAddr_out, 
		output pktEnd_out,
		
		output [7:0] led,
		input [4:0] btn
		
	);
	
	wire wb_rst;
	wire wb_clk;
	
	assign wb_rst = ~rst_n;
/*	assign wb_clk = sys_clk;*/
	
	
	wire       sys_clk_ibufg;
   /* DCM0 wires */
   wire 	   dcm0_clk0_prebufg, dcm0_clk0;
   wire 	   dcm0_clkdv_prebufg, dcm0_clkdv;
   wire 	   dcm0_locked;
	
	 IBUFG sys_clk_in_ibufg
   (
   .I  (sys_clk),
   .O  (sys_clk_ibufg)
   );


   /* DCM providing main system/Wishbone clock */
   DCM_SP dcm0
     (
      // Outputs
      .CLK0                              (dcm0_clk0_prebufg),
      .CLK180                            (),
      .CLK270                            (),
      .CLK2X180                          (),
      .CLK2X                             (),
      .CLK90                             (),
      .CLKDV                             (dcm0_clkdv_prebufg),
      .CLKFX180                          (),
      .CLKFX                             (),
      .LOCKED                            (dcm0_locked),
      // Inputs
      .CLKFB                             (dcm0_clk0),
      .CLKIN                             (sys_clk_ibufg),
      .PSEN                              (1'b0),
      .RST                               (1'b0));
	
	   // Generate 50 MHz from CLKDV
	   defparam    dcm0.CLKDV_DIVIDE      = 2.0;
	
	   BUFG dcm0_clk0_bufg
	     (// Outputs
	      .O                                 (dcm0_clk0),
	      // Inputs
	      .I                                 (dcm0_clk0_prebufg));

	   BUFG dcm0_clkdv_bufg
	     (// Outputs
	      .O                                 (dcm0_clkdv),
	      // Inputs
	      .I                                 (dcm0_clkdv_prebufg));

	   assign wb_clk = dcm0_clkdv;

`ifdef BUS_WIRES

   // mc0 instruction bus wires
   wire [31:0] 	wbs_i_mc0_adr_i;
   wire [31:0]  	wbs_i_mc0_dat_i;
   wire [3:0] 		wbs_i_mc0_sel_i;
   wire 			   wbs_i_mc0_we_i;
   wire 			   wbs_i_mc0_cyc_i;
   wire 			   wbs_i_mc0_stb_i;
   wire [2:0] 	  	wbs_i_mc0_cti_i;
   wire [1:0] 	  	wbs_i_mc0_bte_i;   
   wire [31:0] 	wbs_i_mc0_dat_o;   
   wire 			   wbs_i_mc0_ack_o;
   wire 			   wbs_i_mc0_err_o;
   wire 			   wbs_i_mc0_rty_o;

	assign wbs_i_mc0_adr_i = 0;
	assign wbs_i_mc0_dat_i = 0;
	assign wbs_i_mc0_sel_i = 0;
	assign wbs_i_mc0_we_i  = 0;
	assign wbs_i_mc0_cyc_i = 0;
	assign wbs_i_mc0_stb_i = 0;
	assign wbs_i_mc0_cti_i = 0;
	assign wbs_i_mc0_bte_i = 0; 

   // Data bus slave wires //

   // mc0 data bus wires
   wire [31:0] 			    wbs_d_mc0_adr_i;
   wire [31:0]  wbs_d_mc0_dat_i;
   wire [3:0] 			    wbs_d_mc0_sel_i;
   wire 			    wbs_d_mc0_we_i;
   wire 			    wbs_d_mc0_cyc_i;
   wire 			    wbs_d_mc0_stb_i;
   wire [2:0] 			    wbs_d_mc0_cti_i;
   wire [1:0] 			    wbs_d_mc0_bte_i;   
   wire [31:0]  wbs_d_mc0_dat_o;   
   wire 			    wbs_d_mc0_ack_o;
   wire 			    wbs_d_mc0_err_o;
   wire 			    wbs_d_mc0_rty_o;

	assign wbs_d_mc0_adr_i = 0;
	assign wbs_d_mc0_dat_i = 0;
	assign wbs_d_mc0_sel_i = 0;
	assign wbs_d_mc0_we_i  = 0;
	assign wbs_d_mc0_cyc_i = 0;
	assign wbs_d_mc0_stb_i = 0;
	assign wbs_d_mc0_cti_i = 0;
	assign wbs_d_mc0_bte_i = 0;

   // orlink master wires
   wire [31:0] 	  wbm_orlink_adr_o;
   wire [31:0] 	  wbm_orlink_dat_o;
   wire [3:0] 				  wbm_orlink_sel_o;
   wire 				  wbm_orlink_we_o;
   wire 				  wbm_orlink_cyc_o;
   wire 				  wbm_orlink_stb_o;
   wire [2:0] 				  wbm_orlink_cti_o;
   wire [1:0] 				  wbm_orlink_bte_o;
   wire [31:0]         wbm_orlink_dat_i;
   wire 				  wbm_orlink_ack_i;
   wire 				  wbm_orlink_err_i;
   wire 				  wbm_orlink_rty_i;

`endif

	
	ram_wb xilinx_ddr2_0
	  (
	   .wbm0_adr_i                       (wbm_orlink_adr_o), 
	   .wbm0_bte_i                       (wbm_orlink_bte_o), 
	   .wbm0_cti_i                       (wbm_orlink_cti_o), 
	   .wbm0_cyc_i                       (wbm_orlink_cyc_o), 
	   .wbm0_dat_i                       (wbm_orlink_dat_o), 
	   .wbm0_sel_i                       (wbm_orlink_sel_o),
	   .wbm0_stb_i                       (wbm_orlink_stb_o), 
	   .wbm0_we_i                        (wbm_orlink_we_o),
	   .wbm0_ack_o                       (wbm_orlink_ack_i), 
	   .wbm0_err_o                       (wbm_orlink_err_i), 
	   .wbm0_rty_o                       (wbm_orlink_rty_i), 
	   .wbm0_dat_o                       (wbm_orlink_dat_i),

	   .wbm1_adr_i                       (wbs_d_mc0_adr_i), 
	   .wbm1_bte_i                       (wbs_d_mc0_bte_i), 
	   .wbm1_cti_i                       (wbs_d_mc0_cti_i), 
	   .wbm1_cyc_i                       (wbs_d_mc0_cyc_i), 
	   .wbm1_dat_i                       (wbs_d_mc0_dat_i), 
	   .wbm1_sel_i                       (wbs_d_mc0_sel_i),
	   .wbm1_stb_i                       (wbs_d_mc0_stb_i), 
	   .wbm1_we_i                        (wbs_d_mc0_we_i),
	   .wbm1_ack_o                       (wbs_d_mc0_ack_o), 
	   .wbm1_err_o                       (wbs_d_mc0_err_o), 
	   .wbm1_rty_o                       (wbs_d_mc0_rty_o),
	   .wbm1_dat_o                       (wbs_d_mc0_dat_o),

	   .wbm2_adr_i                       (wbs_i_mc0_adr_i), 
	   .wbm2_bte_i                       (wbs_i_mc0_bte_i), 
	   .wbm2_cti_i                       (wbs_i_mc0_cti_i), 
	   .wbm2_cyc_i                       (wbs_i_mc0_cyc_i), 
	   .wbm2_dat_i                       (wbs_i_mc0_dat_i), 
	   .wbm2_sel_i                       (wbs_i_mc0_sel_i),
	   .wbm2_stb_i                       (wbs_i_mc0_stb_i), 
	   .wbm2_we_i                        (wbs_i_mc0_we_i),
	   .wbm2_ack_o                       (wbs_i_mc0_ack_o), 
	   .wbm2_err_o                       (wbs_i_mc0_err_o), 
	   .wbm2_rty_o                       (wbs_i_mc0_rty_o), 
	   .wbm2_dat_o                       (wbs_i_mc0_dat_o),


	   .wb_clk_i                           (wb_clk),
	   .wb_rst_i                           (wb_rst)
	   );
	
	defparam xilinx_ddr2_0.mem_size_bytes = 32'h0000_0100;
	defparam xilinx_ddr2_0.mem_adr_width = 7;
	
	orlink orlink0 (
		.wb_rst(wb_rst),
		.wb_clk(wb_clk),
		
		.ifclk_in(ifclk_in),
		.fifoData_io(fifoData_io),
		.gotData_in(gotData_in),
		.gotRoom_in(gotRoom_in),

		.sloe_out(sloe_out),     
		.slrd_out(slrd_out),    
		.slwr_out(slwr_out),   
		.fifoAddr_out(fifoAddr_out), 
		.pktEnd_out(pktEnd_out),
		
		.m_wb_adr_o	(wbm_orlink_adr_o[31:0]),
	   .m_wb_sel_o	(wbm_orlink_sel_o[3:0]),
	   .m_wb_we_o 	(wbm_orlink_we_o),
	   .m_wb_dat_o	(wbm_orlink_dat_o[31:0]),
	   .m_wb_cyc_o	(wbm_orlink_cyc_o),
	   .m_wb_stb_o	(wbm_orlink_stb_o),
	   .m_wb_cti_o	(wbm_orlink_cti_o[2:0]),
	   .m_wb_bte_o	(wbm_orlink_bte_o[1:0]),
	   .m_wb_dat_i	(wbm_orlink_dat_i[31:0]),
	   .m_wb_ack_i	(wbm_orlink_ack_i),
	   .m_wb_err_i	(wbm_orlink_err_i),
	
		.led(led)
	
		);
		
/*	assign led = 8'b0;*/
	
endmodule
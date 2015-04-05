
`include "raycast_defines.v"

module raycaster(
		wb_clk,
		wb_rst,

		// WB Slave
		wb_adr_i, wb_dat_i,
		wb_we_i, wb_cyc_i, wb_stb_i,
		wb_cti_i, wb_bte_i,
		wb_dat_o, wb_ack_o, wb_err_o, wb_rty_o,

		// WB Master
		m_wb_adr_o, m_wb_sel_o, m_wb_we_o,
		m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o,
		m_wb_stb_o, m_wb_ack_i, m_wb_err_i,
		m_wb_cti_o, m_wb_bte_o,

		// Interrupt
		irq_o
		);

	// = Parameters =

   // --

	// = Ports =
	input wb_clk;
	input wb_rst;

	// Wishbone Slave
	input [7:0]		wb_adr_i;
	input [7:0]		wb_dat_i;
	input 	  		wb_we_i;
	input 	  		wb_cyc_i;
	input 	  		wb_stb_i;
	input [2:0]		wb_cti_i;
	input [1:0]		wb_bte_i;
	output [7:0] wb_dat_o; // constantly sampling gpio in bus
	output 		  wb_ack_o;
	output 		     wb_err_o;
	output 		     wb_rty_o;

	// Wishbone master
   output [31:0]   m_wb_adr_o;
   output [3:0]    m_wb_sel_o;
   output          m_wb_we_o;
   input [31:0]    m_wb_dat_i;
   output [31:0]   m_wb_dat_o;
   output          m_wb_cyc_o;
   output          m_wb_stb_o;
   input           m_wb_ack_i;
   input           m_wb_err_i;
   output [2:0]    m_wb_cti_o;   // Cycle Type Identifier
   output [1:0]    m_wb_bte_o;   // Burst Type Extension

	//
	output irq_o;

	// --


	// = Wires =

	wire [31:0] cache_hits;
	wire [31:0] cache_miss;

	// Slave -> Controller
	wire rayc_start            ;
	wire [31:0] ray_buf_adr    ;
	wire [31:0] ray_buf_count  ;
	wire [31:0] octree_adr     ;
	wire [31:0] fb_adr         ;

	wire rayc_finished;

	// Controller <-> Master
	wire [31:0]   ctrl_wb_adr_o;
   wire [3:0]    ctrl_wb_sel_o;
   wire          ctrl_wb_we_o ;
   wire [31:0]   ctrl_wb_dat_i;
   wire [31:0]   ctrl_wb_dat_o;
   wire          ctrl_wb_cyc_o;
   wire          ctrl_wb_stb_o;
   wire          ctrl_wb_ack_i;
	wire [2:0]		ctrl_wb_cti_o;
	wire [1:0]		ctrl_wb_bte_o;


	// Cores
`ifdef CORE0
	wire c0_start                 ;
	wire [31:0] c0_root_adr       ;
	wire [2:0] c0_dir_mask        ;
	wire [31:0] c0_tx0            ;
	wire [31:0] c0_ty0            ;
	wire [31:0] c0_tz0            ;
	wire [31:0] c0_tx1            ;
	wire [31:0] c0_ty1            ;
	wire [31:0] c0_tz1            ;

	wire [31:0]		c0_wb_adr_o;
   wire [31:0]    c0_wb_dat_i;
   wire       		c0_wb_cyc_o;
   wire      		c0_wb_stb_o;
   wire           c0_wb_ack_i;

	wire c0_finished              ;
	wire c0_leaf						;
	wire [31:0] c0_final_t        ;
	wire [4:0] c0_final_level    ;
`endif

`ifdef CORE1
	wire c1_start                 ;
	wire [31:0] c1_root_adr       ;
	wire [2:0] c1_dir_mask        ;
	wire [31:0] c1_tx0            ;
	wire [31:0] c1_ty0            ;
	wire [31:0] c1_tz0            ;
	wire [31:0] c1_tx1            ;
	wire [31:0] c1_ty1            ;
	wire [31:0] c1_tz1            ;

	wire [31:0]		c1_wb_adr_o;
   wire [31:0]    c1_wb_dat_i;
   wire       		c1_wb_cyc_o;
   wire      		c1_wb_stb_o;
   wire           c1_wb_ack_i;

	wire c1_finished              ;
	wire c1_leaf						;
	wire [31:0] c1_final_t        ;
	wire [4:0] c1_final_level    ;
`endif

`ifdef CORE2
	wire c2_start                 ;
	wire [31:0] c2_root_adr       ;
	wire [2:0] c2_dir_mask        ;
	wire [31:0] c2_tx0            ;
	wire [31:0] c2_ty0            ;
	wire [31:0] c2_tz0            ;
	wire [31:0] c2_tx1            ;
	wire [31:0] c2_ty1            ;
	wire [31:0] c2_tz1            ;

	wire [31:0]		c2_wb_adr_o;
   wire [31:0]    c2_wb_dat_i;
   wire       		c2_wb_cyc_o;
   wire      		c2_wb_stb_o;
   wire           c2_wb_ack_i;

	wire c2_finished              ;
	wire c2_leaf						;
	wire [31:0] c2_final_t        ;
	wire [4:0] c2_final_level    ;
`endif

`ifdef CORE3
	wire c3_start                 ;
	wire [31:0] c3_root_adr       ;
	wire [2:0] c3_dir_mask        ;
	wire [31:0] c3_tx0            ;
	wire [31:0] c3_ty0            ;
	wire [31:0] c3_tz0            ;
	wire [31:0] c3_tx1            ;
	wire [31:0] c3_ty1            ;
	wire [31:0] c3_tz1            ;

	wire [31:0]		c3_wb_adr_o;
   wire [31:0]    c3_wb_dat_i;
   wire       		c3_wb_cyc_o;
   wire      		c3_wb_stb_o;
   wire           c3_wb_ack_i;

	wire c3_finished              ;
	wire c3_leaf						;
	wire [31:0] c3_final_t        ;
	wire [4:0] c3_final_level    ;
`endif

	// --


	// = Raycast Control =
	raycast_ctrl raycast_ctrl
		(
			.clk (wb_clk),
			.rst (wb_rst),

			.rayc_start_i     (rayc_start   ),
			.ray_buf_adr_i    (ray_buf_adr  ),
			.ray_buf_count_i  (ray_buf_count),
			.octree_adr_i     (octree_adr   ),
			.fb_adr_i         (fb_adr       ),

			.m_wb_adr_o       (ctrl_wb_adr_o),
			.m_wb_sel_o       (ctrl_wb_sel_o),
			.m_wb_we_o        (ctrl_wb_we_o ),
			.m_wb_dat_o       (ctrl_wb_dat_o),
			.m_wb_dat_i       (ctrl_wb_dat_i),
			.m_wb_cyc_o       (ctrl_wb_cyc_o),
			.m_wb_stb_o       (ctrl_wb_stb_o),
			.m_wb_ack_i       (ctrl_wb_ack_i),
			.m_wb_cti_o	(ctrl_wb_cti_o),
			.m_wb_bte_o (ctrl_wb_bte_o),

/*			.ctrl_adr_o (ctrl_adr),
			.ray_data_req_o   (ray_data_req ),
			.ray_data_ack_i   (ray_data_ack ),
			.ray_data_i       (ray_data     ),
			.fb_w_req_o       (fb_w_req     ),
			.fb_w_dat_o       (fb_w_dat     ),
			.fb_w_ack_i       (fb_w_ack     ),*/

`ifdef CORE0
			.c0_start_o      (c0_start   ),
			.c0_root_adr_o   (c0_root_adr),
			.c0_dir_mask_o   (c0_dir_mask),
			.c0_tx0_o        (c0_tx0     ),
			.c0_ty0_o        (c0_ty0     ),
			.c0_tz0_o        (c0_tz0     ),
			.c0_tx1_o        (c0_tx1     ),
			.c0_ty1_o        (c0_ty1     ),
			.c0_tz1_o        (c0_tz1     ),
			.c0_finished_i		(c0_finished),
			.c0_leaf_i 			(c0_leaf),
			.c0_final_t_i 		(c0_final_t),
			.c0_final_level_i (c0_final_level),
`endif

`ifdef CORE1
			.c1_start_o      (c1_start   ),
			.c1_root_adr_o   (c1_root_adr),
			.c1_dir_mask_o   (c1_dir_mask),
			.c1_tx0_o        (c1_tx0     ),
			.c1_ty0_o        (c1_ty0     ),
			.c1_tz0_o        (c1_tz0     ),
			.c1_tx1_o        (c1_tx1     ),
			.c1_ty1_o        (c1_ty1     ),
			.c1_tz1_o        (c1_tz1     ),
			.c1_finished_i		(c1_finished),
			.c1_leaf_i 			(c1_leaf),
			.c1_final_t_i 		(c1_final_t),
			.c1_final_level_i (c1_final_level),
`endif

`ifdef CORE2
			.c2_start_o      (c2_start   ),
			.c2_root_adr_o   (c2_root_adr),
			.c2_dir_mask_o   (c2_dir_mask),
			.c2_tx0_o        (c2_tx0     ),
			.c2_ty0_o        (c2_ty0     ),
			.c2_tz0_o        (c2_tz0     ),
			.c2_tx1_o        (c2_tx1     ),
			.c2_ty1_o        (c2_ty1     ),
			.c2_tz1_o        (c2_tz1     ),
			.c2_finished_i		(c2_finished),
			.c2_leaf_i 			(c2_leaf),
			.c2_final_t_i 		(c2_final_t),
			.c2_final_level_i (c2_final_level),
`endif

`ifdef CORE3
			.c3_start_o      (c3_start   ),
			.c3_root_adr_o   (c3_root_adr),
			.c3_dir_mask_o   (c3_dir_mask),
			.c3_tx0_o        (c3_tx0     ),
			.c3_ty0_o        (c3_ty0     ),
			.c3_tz0_o        (c3_tz0     ),
			.c3_tx1_o        (c3_tx1     ),
			.c3_ty1_o        (c3_ty1     ),
			.c3_tz1_o        (c3_tz1     ),
			.c3_finished_i		(c3_finished),
			.c3_leaf_i 			(c3_leaf),
			.c3_final_t_i 		(c3_final_t),
			.c3_final_level_i (c3_final_level),
`endif

	.rayc_finished_o (rayc_finished)

		);
	// --

	// = Raycast master interface =
	raycast_master raycast_master
		(
			// .cache_hits (cache_hits),
			// .cache_miss (cache_miss),

			.m_wb_adr_o     (m_wb_adr_o ),
			.m_wb_sel_o     (m_wb_sel_o ),
			.m_wb_we_o      (m_wb_we_o  ),
			.m_wb_dat_o     (m_wb_dat_o ),
			.m_wb_dat_i     (m_wb_dat_i ),
			.m_wb_cyc_o     (m_wb_cyc_o ),
			.m_wb_stb_o     (m_wb_stb_o ),
			.m_wb_ack_i     (m_wb_ack_i ),
			.m_wb_err_i     (m_wb_err_i ),
			.m_wb_cti_o     (m_wb_cti_o ),
			.m_wb_bte_o     (m_wb_bte_o ),


         .ctrl_wb_adr_i    (ctrl_wb_adr_o),
			.ctrl_wb_sel_i	   (ctrl_wb_sel_o),
         .ctrl_wb_we_i     (ctrl_wb_we_o ),
			.ctrl_wb_dat_o    (ctrl_wb_dat_i),
			.ctrl_wb_dat_i    (ctrl_wb_dat_o),
			.ctrl_wb_cyc_i    (ctrl_wb_cyc_o),
			.ctrl_wb_stb_i    (ctrl_wb_stb_o),
			.ctrl_wb_ack_o    (ctrl_wb_ack_i),
			.ctrl_wb_cti_i (ctrl_wb_cti_o),
			.ctrl_wb_bte_i (ctrl_wb_bte_o),

`ifdef CORE0
			.c0_wb_adr_i   (c0_wb_adr_o),
			.c0_wb_dat_o   (c0_wb_dat_i),
			.c0_wb_cyc_i   (c0_wb_cyc_o),
			.c0_wb_stb_i   (c0_wb_stb_o),
			.c0_wb_ack_o   (c0_wb_ack_i),
`endif

`ifdef CORE1
			.c1_wb_adr_i   (c1_wb_adr_o),
			.c1_wb_dat_o   (c1_wb_dat_i),
			.c1_wb_cyc_i   (c1_wb_cyc_o),
			.c1_wb_stb_i   (c1_wb_stb_o),
			.c1_wb_ack_o   (c1_wb_ack_i),
`endif

`ifdef CORE2
			.c2_wb_adr_i   (c2_wb_adr_o),
			.c2_wb_dat_o   (c2_wb_dat_i),
			.c2_wb_cyc_i   (c2_wb_cyc_o),
			.c2_wb_stb_i   (c2_wb_stb_o),
			.c2_wb_ack_o   (c2_wb_ack_i),
`endif

`ifdef CORE3
			.c3_wb_adr_i   (c3_wb_adr_o),
			.c3_wb_dat_o   (c3_wb_dat_i),
			.c3_wb_cyc_i   (c3_wb_cyc_o),
			.c3_wb_stb_i   (c3_wb_stb_o),
			.c3_wb_ack_o   (c3_wb_ack_i),
`endif

			.wb_clk			 (wb_clk     ),
			.wb_rst         (wb_rst     )
		);
	// --

	// = Raycast slave interface =
	raycast_slave raycast_slave
		(
			.wb_clk          (wb_clk  ),
			.wb_rst          (wb_rst  ),
			.wb_adr_i        (wb_adr_i),
			.wb_dat_i        (wb_dat_i),
			.wb_we_i         (wb_we_i ),
			.wb_cyc_i        (wb_cyc_i),
			.wb_stb_i        (wb_stb_i),
			.wb_cti_i        (wb_cti_i),
			.wb_bte_i        (wb_bte_i),
			.wb_dat_o        (wb_dat_o),
			.wb_ack_o        (wb_ack_o),
			.wb_err_o        (wb_err_o),
			.wb_rty_o        (wb_rty_o),


			.rayc_start_o    (rayc_start   ),
			.ray_buf_adr_o   (ray_buf_adr  ),
			.ray_buf_count_o (ray_buf_count),
			.octree_adr_o    (octree_adr   ),
			.fb_adr_o        (fb_adr       ),
			.rayc_finished_i (rayc_finished),

			.cache_hits_i (cache_hits),
			.cache_miss_i (cache_miss),

			.irq_o (irq_o)
		);

	// --

	// = Raycast cores =
`ifdef CORE0
	raycast_core core0
		(
			.clk                (wb_clk                ),
			.rst                (wb_rst                ),

			.start_i            (c0_start            ),
			.root_adr_i         (c0_root_adr         ),
			.dir_mask_i         (c0_dir_mask         ),
			.tx0_i              (c0_tx0              ),
			.ty0_i              (c0_ty0              ),
			.tz0_i              (c0_tz0              ),
			.tx1_i              (c0_tx1              ),
			.ty1_i              (c0_ty1              ),
			.tz1_i              (c0_tz1              ),

			.m_wb_adr_o        (c0_wb_adr_o),
			.m_wb_dat_i        (c0_wb_dat_i),
			.m_wb_cyc_o        (c0_wb_cyc_o),
			.m_wb_stb_o        (c0_wb_stb_o),
			.m_wb_ack_i        (c0_wb_ack_i),

			.finished_o         (c0_finished         ),
			.leaf_o					(c0_leaf),
			.t_o                (c0_final_t           ),
			.level_o            (c0_final_level       )
		);
`endif

`ifdef CORE1
	raycast_core core1
		(
			.clk                (wb_clk                ),
			.rst                (wb_rst                ),

			.start_i            (c1_start            ),
			.root_adr_i         (c1_root_adr         ),
			.dir_mask_i         (c1_dir_mask         ),
			.tx0_i              (c1_tx0              ),
			.ty0_i              (c1_ty0              ),
			.tz0_i              (c1_tz0              ),
			.tx1_i              (c1_tx1              ),
			.ty1_i              (c1_ty1              ),
			.tz1_i              (c1_tz1              ),

			.m_wb_adr_o        (c1_wb_adr_o),
			.m_wb_dat_i        (c1_wb_dat_i),
			.m_wb_cyc_o        (c1_wb_cyc_o),
			.m_wb_stb_o        (c1_wb_stb_o),
			.m_wb_ack_i        (c1_wb_ack_i),

			.finished_o         (c1_finished         ),
			.leaf_o					(c1_leaf),
			.t_o                (c1_final_t           ),
			.level_o            (c1_final_level       )
		);
`endif

`ifdef CORE2
	raycast_core core2
		(
			.clk                (wb_clk                ),
			.rst                (wb_rst                ),

			.start_i            (c2_start            ),
			.root_adr_i         (c2_root_adr         ),
			.dir_mask_i         (c2_dir_mask         ),
			.tx0_i              (c2_tx0              ),
			.ty0_i              (c2_ty0              ),
			.tz0_i              (c2_tz0              ),
			.tx1_i              (c2_tx1              ),
			.ty1_i              (c2_ty1              ),
			.tz1_i              (c2_tz1              ),

			.m_wb_adr_o        (c2_wb_adr_o),
			.m_wb_dat_i        (c2_wb_dat_i),
			.m_wb_cyc_o        (c2_wb_cyc_o),
			.m_wb_stb_o        (c2_wb_stb_o),
			.m_wb_ack_i        (c2_wb_ack_i),

			.finished_o         (c2_finished         ),
			.leaf_o					(c2_leaf),
			.t_o                (c2_final_t           ),
			.level_o            (c2_final_level       )
		);
`endif

`ifdef CORE3
	raycast_core core3
		(
			.clk                (wb_clk                ),
			.rst                (wb_rst                ),

			.start_i            (c3_start            ),
			.root_adr_i         (c3_root_adr         ),
			.dir_mask_i         (c3_dir_mask         ),
			.tx0_i              (c3_tx0              ),
			.ty0_i              (c3_ty0              ),
			.tz0_i              (c3_tz0              ),
			.tx1_i              (c3_tx1              ),
			.ty1_i              (c3_ty1              ),
			.tz1_i              (c3_tz1              ),

			.m_wb_adr_o        (c3_wb_adr_o),
			.m_wb_dat_i        (c3_wb_dat_i),
			.m_wb_cyc_o        (c3_wb_cyc_o),
			.m_wb_stb_o        (c3_wb_stb_o),
			.m_wb_ack_i        (c3_wb_ack_i),

			.finished_o         (c3_finished         ),
			.leaf_o					(c3_leaf),
			.t_o                (c3_final_t           ),
			.level_o            (c3_final_level       )
		);
`endif
	// --







endmodule // raycaster
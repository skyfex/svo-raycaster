`include "raycast_defines.v"

module raycast_ctrl
	(
		clk, rst,

		// Signals from slave
		rayc_start_i,
		ray_buf_adr_i, ray_buf_count_i,
		octree_adr_i, fb_adr_i,

		// WB Master
	   m_wb_adr_o, m_wb_sel_o, m_wb_we_o,
	   m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o,
	   m_wb_stb_o, m_wb_ack_i,
		m_wb_cti_o, m_wb_bte_o,

`ifdef CORE0
		c0_start_o,
		c0_root_adr_o, c0_dir_mask_o,
		c0_tx0_o, c0_ty0_o, c0_tz0_o,
		c0_tx1_o, c0_ty1_o, c0_tz1_o,
		c0_finished_i,	c0_leaf_i,
		c0_final_t_i, c0_final_level_i,
`endif
`ifdef CORE1
		c1_start_o,
		c1_root_adr_o, c1_dir_mask_o,
		c1_tx0_o, c1_ty0_o, c1_tz0_o,
		c1_tx1_o, c1_ty1_o, c1_tz1_o,
		c1_finished_i,	c1_leaf_i,
		c1_final_t_i, c1_final_level_i,
`endif
`ifdef CORE2
		c2_start_o,
		c2_root_adr_o, c2_dir_mask_o,
		c2_tx0_o, c2_ty0_o, c2_tz0_o,
		c2_tx1_o, c2_ty1_o, c2_tz1_o,
		c2_finished_i,	c2_leaf_i,
		c2_final_t_i, c2_final_level_i,
`endif
`ifdef CORE3
		c3_start_o,
		c3_root_adr_o, c3_dir_mask_o,
		c3_tx0_o, c3_ty0_o, c3_tz0_o,
		c3_tx1_o, c3_ty1_o, c3_tz1_o,
		c3_finished_i,	c3_leaf_i,
		c3_final_t_i, c3_final_level_i,
`endif
		rayc_finished_o
	);

	// = Parameters =
	parameter dw = 32;
	// --

	// = Ports =
	input clk;
	input rst;

	input 			rayc_start_i;
	input [31:0]	ray_buf_adr_i;
	input [31:0]	ray_buf_count_i;
	input [31:0]	octree_adr_i;
	input [31:0]	fb_adr_i;

	output reg [31:0]		m_wb_adr_o;
   output reg [3:0] 		m_wb_sel_o;
   output reg      		m_wb_we_o;
   input [31:0]    		m_wb_dat_i;
   output reg [31:0]		m_wb_dat_o;
   output reg      		m_wb_cyc_o;
   output reg      		m_wb_stb_o;
   input           		m_wb_ack_i;
	output reg [2:0]    m_wb_cti_o;   // Cycle Type Identifier
   output reg [1:0]    m_wb_bte_o;   // Burst Type Extension

`ifdef CORE0
	output 			c0_start_o;
	output [31:0] 		c0_root_adr_o;
	output [2:0] 		c0_dir_mask_o;
	output [dw-1:0] 	c0_tx0_o, c0_ty0_o, c0_tz0_o;
	output [dw-1:0] 	c0_tx1_o, c0_ty1_o, c0_tz1_o;

	input c0_finished_i;
	input c0_leaf_i 	;
	input [31:0] c0_final_t_i ;
	input [4:0] c0_final_level_i;
`endif
`ifdef CORE1
	output 			c1_start_o;
	output [31:0] 		c1_root_adr_o;
	output [2:0] 		c1_dir_mask_o;
	output [dw-1:0] 	c1_tx0_o, c1_ty0_o, c1_tz0_o;
	output [dw-1:0] 	c1_tx1_o, c1_ty1_o, c1_tz1_o;

	input c1_finished_i;
	input c1_leaf_i 	;
	input [31:0] c1_final_t_i ;
	input [4:0] c1_final_level_i;
`endif
`ifdef CORE2
	output 			c2_start_o;
	output [31:0] 		c2_root_adr_o;
	output [2:0] 		c2_dir_mask_o;
	output [dw-1:0] 	c2_tx0_o, c2_ty0_o, c2_tz0_o;
	output [dw-1:0] 	c2_tx1_o, c2_ty1_o, c2_tz1_o;

	input c2_finished_i;
	input c2_leaf_i 	;
	input [31:0] c2_final_t_i ;
	input [4:0] c2_final_level_i;
`endif
`ifdef CORE3
	output 			c3_start_o;
	output [31:0] 		c3_root_adr_o;
	output [2:0] 		c3_dir_mask_o;
	output [dw-1:0] 	c3_tx0_o, c3_ty0_o, c3_tz0_o;
	output [dw-1:0] 	c3_tx1_o, c3_ty1_o, c3_tz1_o;

	input c3_finished_i;
	input c3_leaf_i 	;
	input [31:0] c3_final_t_i ;
	input [4:0] c3_final_level_i;
`endif

	output reg rayc_finished_o;


	// --

	// = States =
	parameter STATE_WIDTH = 4;
	parameter S_IDLE = 0, S_PAR_READ = 1, S_PAR_STB = 2,
		S_FIND_CORE = 3, S_START_CORE = 4,
		S_FB_WRITE = 5, S_FB_FLUSH = 6,
		S_FINISHED = 7;

	// --

	// = Registers =
	reg [STATE_WIDTH-1:0] state, state_n;
	reg [31:0] ray_adr, ray_adr_n;		// Current ray adr
	reg [31:0] ray_count, ray_count_n;	// Current ray count TODO: Could save some bits here
	reg [31:0] fb_adr, fb_adr_n;

	reg [31:0] m_wb_adr_o_n;
	reg [31:0] m_wb_dat_o_n;
	reg [4:0] m_wb_sel_o_n;

	reg [31:0] parameters[0:6];
	reg [2:0] par_idx, par_idx_n;

	reg [23:0] pixel_val_n, pixel_val;

	reg [2:0] fb_buf_idx, fb_buf_idx_n;
	reg [23:0] fb_buf[0:7];
	reg [31:0] fb_buf_out[0:5];

	reg [3:0] core_idx;
	reg cx_started[0:`RAYC_CORE_COUNT];
	reg fake_start;
	reg finished, finished_n;

	// --

	// = Wires =
	reg init;
	reg core_idx_inc;

	wire [31:0] ray_adr_plus = ray_adr + 32'd4;
	wire [31:0] ray_count_minus = ray_count - 32'd1;

	reg parameter_store;

	reg fb_write;

	wire all_cores_stopped;

	wire			cx_finished_i [0:`RAYC_CORE_COUNT-1];
	wire 			cx_leaf_i	  [0:`RAYC_CORE_COUNT-1];
	wire [31:0] 	cx_final_t_i  [0:`RAYC_CORE_COUNT-1];
	reg 			cx_start_o	  [0:`RAYC_CORE_COUNT-1];
	reg 			cx_flush		  [0:`RAYC_CORE_COUNT-1];

	// wire [31:0] ray_fb_adr  = parameters[0];
	wire [31:0] ray_masks   = parameters[0];
	wire [31:0] ray_tx0     = parameters[1];
	wire [31:0] ray_ty0     = parameters[2];
	wire [31:0] ray_tz0     = parameters[3];
	wire [31:0] ray_tx1     = parameters[4];
	wire [31:0] ray_ty1	    = parameters[5];
	wire [31:0] ray_tz1     = parameters[6];

	wire ignore_ray = ray_masks[31];

	wire [23:0] test1 = fb_buf[0];
	wire [23:0] test2 = fb_buf[7];
	wire [31:0] test3 = fb_buf_out[0];
	wire [31:0] test4 = fb_buf_out[5];
	// --

	// = Assignments =


`ifdef CORE0
	assign c0_root_adr_o = octree_adr_i;
	assign c0_dir_mask_o = ray_masks[2:0];
	assign c0_tx0_o = ray_tx0;
	assign c0_ty0_o = ray_ty0;
	assign c0_tz0_o = ray_tz0;
	assign c0_tx1_o = ray_tx1;
	assign c0_ty1_o = ray_ty1;
	assign c0_tz1_o = ray_tz1;
	assign c0_start_o = cx_start_o[0];
	assign cx_leaf_i[0] = c0_leaf_i;
	assign cx_final_t_i[0] = c0_final_t_i;
	assign cx_finished_i[0] = c0_finished_i;
`endif
`ifdef CORE1
	assign c1_root_adr_o = octree_adr_i;
	assign c1_dir_mask_o = ray_masks[2:0];
	assign c1_tx0_o = ray_tx0;
	assign c1_ty0_o = ray_ty0;
	assign c1_tz0_o = ray_tz0;
	assign c1_tx1_o = ray_tx1;
	assign c1_ty1_o = ray_ty1;
	assign c1_tz1_o = ray_tz1;
	assign c1_start_o = cx_start_o[1];
	assign cx_leaf_i[1] = c1_leaf_i;
	assign cx_final_t_i[1] = c1_final_t_i;
	assign cx_finished_i[1] = c1_finished_i;
`endif
`ifdef CORE2
	assign c2_root_adr_o = octree_adr_i;
	assign c2_dir_mask_o = ray_masks[2:0];
	assign c2_tx0_o = ray_tx0;
	assign c2_ty0_o = ray_ty0;
	assign c2_tz0_o = ray_tz0;
	assign c2_tx1_o = ray_tx1;
	assign c2_ty1_o = ray_ty1;
	assign c2_tz1_o = ray_tz1;
	assign c2_start_o = cx_start_o[2];
	assign cx_leaf_i[2] = c2_leaf_i;
	assign cx_final_t_i[2] = c2_final_t_i;
	assign cx_finished_i[2] = c2_finished_i;
`endif
`ifdef CORE3
	assign c3_root_adr_o = octree_adr_i;
	assign c3_dir_mask_o = ray_masks[2:0];
	assign c3_tx0_o = ray_tx0;
	assign c3_ty0_o = ray_ty0;
	assign c3_tz0_o = ray_tz0;
	assign c3_tx1_o = ray_tx1;
	assign c3_ty1_o = ray_ty1;
	assign c3_tz1_o = ray_tz1;
	assign c3_start_o = cx_start_o[3];
	assign cx_leaf_i[3] = c3_leaf_i;
	assign cx_final_t_i[3] = c3_final_t_i;
	assign cx_finished_i[3] = c3_finished_i;
`endif

	// --

	assign all_cores_stopped =
		`ifdef CORE0
			!cx_started[0] &&
		`endif
		`ifdef CORE1
		 	!cx_started[1] &&
		`endif
		`ifdef CORE2
			!cx_started[2] &&
		`endif
		`ifdef CORE3
		 	!cx_started[3] &&
		`endif
		1;

	integer i;
	reg m_wb_cyc_o_b;
	reg m_wb_stb_o_b;
	reg m_wb_we_o_b;
	reg [2:0] m_wb_cti_o_b;
	reg [1:0] m_wb_bte_o_b;

	always @(*)
	begin
		ray_adr_n = ray_adr;
		ray_count_n = ray_count;
		state_n = state;
		fb_adr_n = fb_adr;

		m_wb_cyc_o_b = 0;
		m_wb_stb_o_b = 0;
		m_wb_we_o_b = 0;
		m_wb_cti_o_b = 3'b0;
		m_wb_bte_o_b = 2'b0;


		m_wb_adr_o_n = m_wb_adr_o;
		m_wb_dat_o_n = m_wb_dat_o;
		m_wb_sel_o_n = m_wb_sel_o;

		// pixel_val_n = pixel_val;
		par_idx_n = par_idx;
		parameter_store = 0;

		fb_buf_idx_n = fb_buf_idx;
		fb_write = 0;

		fake_start = 0;
		finished_n = finished;
		rayc_finished_o = 0;

		init = 0;
		core_idx_inc = 0;

		for (i=0;i<`RAYC_CORE_COUNT;i=i+1) begin
			cx_flush[i] = 0;
			cx_start_o[i] = 0;
		end

		case (state)
			S_IDLE: begin
				finished_n = 0;
				if (rayc_start_i) begin
					// Considered sampling all the parameters/addresses here, but I'd rather
					// TODO: send a signal to raycast_slave to set them to read-only
					init = 1;

					ray_count_n = ray_buf_count_i;
					par_idx_n = 0;

					ray_adr_n = ray_buf_adr_i;
					m_wb_adr_o_n = ray_adr_n;
					fb_adr_n = fb_adr_i;
					fb_buf_idx_n = 0;


					state_n = S_PAR_READ;
				end
			end


			S_PAR_READ: begin
				m_wb_cyc_o_b = 1;
				m_wb_stb_o_b = 1;
				m_wb_cti_o_b = 3'b010; // Linear increment burst
				state_n = S_PAR_STB;
			end

			S_PAR_STB: begin
				m_wb_cyc_o_b = 1;
				m_wb_stb_o_b = 1;
				if (par_idx==3'd6)
					m_wb_cti_o_b = 3'b111;
				else
					m_wb_cti_o_b = 3'b010; // Linear increment burst
				if (m_wb_ack_i) begin
					parameter_store = 1;
					ray_adr_n = ray_adr_plus;
					m_wb_adr_o_n = ray_adr_plus;
					par_idx_n = par_idx+1;
					if (par_idx==3'd6) begin
						par_idx_n = 0;
						state_n = S_FIND_CORE;
					end
					else begin
						state_n = S_PAR_STB;
					end
				end
			end

			S_FIND_CORE: begin // 3

				if (cx_finished_i[core_idx]) begin

					if (cx_started[core_idx]) begin
						// Core started and finished, write output pixel
						if (!ignore_ray && cx_leaf_i[core_idx]) begin
							pixel_val_n = {cx_final_t_i[core_idx][13:6], 16'h0000};
							// pixel_val_n = {24'hFFFFFF};
							// case (core_idx)
							// 	0:	pixel_val_n = {24'hFF0000};
							// 	1: pixel_val_n = {24'h00FF00};
							// 	2: pixel_val_n = {24'h2222FF};
							// 	3: pixel_val_n = {24'hFFFF00};
							// endcase
						end
						else begin
							pixel_val_n = {24'h00000};
						end
						state_n = S_FB_WRITE;
					end

					else if (ray_count == 32'd0) begin
						// All rays scheduled
						if (all_cores_stopped) begin
							// All cores finished, we're done
							// state_n = S_FINISHED;
							finished_n = 1;
							fb_buf_idx_n = 1;
							m_wb_adr_o_n = fb_adr;
							m_wb_dat_o_n = fb_buf_out[0];
							state_n = S_FB_FLUSH;
						end
						else begin
							// Wait for other cores to finish
							core_idx_inc = 1;
							state_n = S_FIND_CORE;
						end
					end

					else begin
						// Start next core
						state_n = S_START_CORE;
					end
				end
				else begin
					// core_idx_inc = 1;
					state_n = S_FIND_CORE;
				end

			end

			S_START_CORE: begin // 4

				if (ignore_ray)
					fake_start = 1;
				else begin
					cx_start_o[core_idx] = 1;
					core_idx_inc = 1;
				end

				ray_count_n = ray_count_minus;
				par_idx_n = 0;
				m_wb_adr_o_n = ray_adr;

				if (ray_count == 32'd1)
					state_n = S_FIND_CORE;
				else
					state_n = S_PAR_READ;
			end

			S_FB_WRITE: begin
				fb_write = 1;
				cx_flush[core_idx] = 1;
				if (fb_buf_idx==3'd7) begin
					fb_buf_idx_n = 1;
					m_wb_adr_o_n = fb_adr;
					m_wb_dat_o_n = fb_buf_out[0];
					state_n = S_FB_FLUSH;
				end else
				begin
					fb_buf_idx_n = fb_buf_idx+1;
					state_n = S_FIND_CORE;
				end
			end

			S_FB_FLUSH: begin
				m_wb_cyc_o_b = 1;
				m_wb_stb_o_b = 1;
				m_wb_we_o_b = 1;
				if (fb_buf_idx==6)
					m_wb_cti_o_b = 3'b111; // End-of-burst
				else
					m_wb_cti_o_b = 3'b010; // Linear increment burst
				if (m_wb_ack_i) begin
					fb_adr_n = fb_adr+32'd4;
					m_wb_adr_o_n = fb_adr+32'd4;
					if (fb_buf_idx==6) begin
						fb_buf_idx_n = 0;
						if (finished)
							state_n = S_FINISHED;
						else
							state_n = S_FIND_CORE;
					end
					else begin
						fb_buf_idx_n = fb_buf_idx+1;
						m_wb_dat_o_n = fb_buf_out[fb_buf_idx];
						state_n = S_FB_FLUSH;
					end
				end
			end

			S_FINISHED: begin
				rayc_finished_o = 1;
				state_n = S_IDLE;
			end
		endcase

		m_wb_cyc_o <= m_wb_cyc_o_b;
		m_wb_stb_o <= m_wb_stb_o_b;
		m_wb_we_o  <= m_wb_we_o_b;
		m_wb_cti_o <= m_wb_cti_o_b;
		m_wb_bte_o <= m_wb_bte_o_b;
	end



	// = Simple registers =
	always @(posedge clk)
	begin
		if (rst) begin
			state <= S_IDLE;
			// ray_adr <= 32'd0;
			// ray_count <= 32'd0;
			// fb_adr <= 32'd0;

			m_wb_adr_o <= 32'd0;
			m_wb_dat_o <= 32'd0;
			m_wb_sel_o <= 4'b1111;

			// pixel_val <= 24'b0;

			par_idx <= 3'd0;
		end
		else begin
			state <= state_n;
			ray_adr <= ray_adr_n;
			ray_count <= ray_count_n;
			fb_adr <= fb_adr_n;
			fb_buf_idx <= fb_buf_idx_n;

			m_wb_adr_o <= m_wb_adr_o_n;
			m_wb_dat_o <= m_wb_dat_o_n;
			m_wb_sel_o <= m_wb_sel_o_n;

			pixel_val <= pixel_val_n;

			par_idx <= par_idx_n;
			finished <= finished_n;
		end
	end
	// --

	// = core_idx register =
	always @(posedge clk)
	begin
		if (init) begin
			core_idx <= 0;
		end
		else if (core_idx_inc) begin
			if (core_idx == (`RAYC_CORE_COUNT-1))
				// If we set the bit width of core_idx right, we can just let this overflow instead
				core_idx <= 0;
			else
				core_idx <= core_idx+1;
		end
	end
	// --


	// = cx_fb_adr and cx_started registers =
	always @(posedge clk)
	begin
		for (i=0; i<`RAYC_CORE_COUNT; i=i+1) begin
			if (rst) begin
				cx_started[i] <= 0;
			end
			if (fake_start || cx_start_o[i]) begin
				cx_started[i] <= 1;
			end
			else if (cx_flush[i]) begin
				cx_started[i] <= 0;
			end
		end
	end
	// --

	// = Parameters =
	always @(posedge clk)
	begin
		if (parameter_store) begin
			parameters[par_idx] <= m_wb_dat_i;
		end
	end
	// --


	always @(posedge clk)
	begin
		if (fb_write) begin
			fb_buf[fb_buf_idx] <= pixel_val;
		end
	end

	always @(*)
	begin
		fb_buf_out[0] = {fb_buf[0],       fb_buf[1][23:16]};
		fb_buf_out[1] = {fb_buf[1][15:0], fb_buf[2][23:8]};
		fb_buf_out[2] = {fb_buf[2][7:0],  fb_buf[3]};
		fb_buf_out[3] = {fb_buf[4],       fb_buf[5][23:16]};
		fb_buf_out[4] = {fb_buf[5][15:0], fb_buf[6][23:8]};
		fb_buf_out[5] = {fb_buf[6][7:0],  fb_buf[7]};

	end

	// --

endmodule
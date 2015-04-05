/*
 *	Registers:
 * 0: Control (Bit 7..1: Reserved; Bit 0: Start)
 * 1: Reserved
 * 2: Reserved
 * 3: Reserved
 * 7..4:	   Ray buffer address
 * 11..8:   Ray count (in buffer)
 * 15..12:  Octree address
 * 19..16:	Framebuffer address
 */

module raycast_slave
	(
		wb_clk,
		wb_rst,

		// WB Slave
		wb_adr_i, wb_dat_i,
		wb_we_i, wb_cyc_i, wb_stb_i,
		wb_cti_i, wb_bte_i,
		wb_dat_o, wb_ack_o, wb_err_o, wb_rty_o,

		rayc_start_o,
		ray_buf_adr_o, ray_buf_count_o, octree_adr_o, fb_adr_o,
		rayc_finished_i,

		cache_hits_i,
		cache_miss_i,

		irq_o
	);


	// = Ports =
	input wb_clk;
	input wb_rst;

	input [7:0]			wb_adr_i;
	input [7:0]			wb_dat_i;
	input 	  			wb_we_i;
	input 	  			wb_cyc_i;
	input 	  			wb_stb_i;
	input [2:0]			wb_cti_i;
	input [1:0]			wb_bte_i;
	output reg [7:0]	wb_dat_o;
	output reg 		 	wb_ack_o;
	output 		    	wb_err_o;
	output 		    	wb_rty_o;

	output rayc_start_o;
	output [31:0] ray_buf_adr_o;
	output [31:0] ray_buf_count_o;
	output [31:0] octree_adr_o;
	output [31:0] fb_adr_o;
	input rayc_finished_i;

	input [31:0] cache_miss_i;
	input [31:0] cache_hits_i;

	output irq_o;
	// --

	// = Registers =
	reg [7:0] control_reg; // 0: rayc_start
	reg [7:0] status_reg;
	reg [31:0] ray_buf_adr_reg;
	reg [31:0] ray_buf_count_reg;
	reg [31:0] octree_adr_reg;
	reg [31:0] fb_adr_reg;
	// --

	// = Assignments =
	assign rayc_start_o    = control_reg[0];
	assign ray_buf_adr_o      = ray_buf_adr_reg;
	assign ray_buf_count_o	  = ray_buf_count_reg;
	assign octree_adr_o	  = octree_adr_reg;
	assign fb_adr_o        = fb_adr_reg;

	assign irq_o = status_reg[0];
	// --

	// = Register writes =
	always @(posedge wb_clk)
		if (wb_rst)
		begin
			control_reg <= 8'b0;
			ray_buf_adr_reg <= 32'd83886084;
			ray_buf_count_reg <= 32'd307200;
			octree_adr_reg <= 32'd100857520;
		end
		else if (wb_stb_i & wb_we_i) // & wb_cyc_i ?
		begin
			case (wb_adr_i)
				0:  begin
					control_reg <= wb_dat_i;
				end

				4:  ray_buf_adr_reg[31:24] <= wb_dat_i;
				5:  ray_buf_adr_reg[23:16] <= wb_dat_i;
				6:  ray_buf_adr_reg[15: 8] <= wb_dat_i;
				7:  ray_buf_adr_reg[ 7: 0] <= wb_dat_i;

				8:  ray_buf_count_reg[31:24] <= wb_dat_i;
				9:  ray_buf_count_reg[23:16] <= wb_dat_i;
				10: ray_buf_count_reg[15: 8] <= wb_dat_i;
				11: ray_buf_count_reg[ 7: 0] <= wb_dat_i;

				12: octree_adr_reg[31:24] <= wb_dat_i;
				13: octree_adr_reg[23:16] <= wb_dat_i;
				14: octree_adr_reg[15: 8] <= wb_dat_i;
				15: octree_adr_reg[ 7: 0] <= wb_dat_i;

				16: fb_adr_reg[31:24] <= wb_dat_i;
				17: fb_adr_reg[23:16] <= wb_dat_i;
				18: fb_adr_reg[15: 8] <= wb_dat_i;
				19: fb_adr_reg[ 7: 0] <= wb_dat_i;
			endcase
		end
		else begin
			// Strobe signals reset
			control_reg[0] <= 0;
		end
	// --

	//  = Register read =
	always @(posedge wb_clk)
	  begin
		case (wb_adr_i)
			0:  wb_dat_o <= control_reg;
			1:  wb_dat_o <= status_reg;
			4:  wb_dat_o <= ray_buf_adr_reg[31:24];
			5:  wb_dat_o <= ray_buf_adr_reg[23:16];
			6:  wb_dat_o <= ray_buf_adr_reg[15: 8];
			7:  wb_dat_o <= ray_buf_adr_reg[ 7: 0];

			8:  wb_dat_o <= ray_buf_count_reg[31:24];
			9:  wb_dat_o <= ray_buf_count_reg[23:16];
			10: wb_dat_o <= ray_buf_count_reg[15: 8];
			11: wb_dat_o <= ray_buf_count_reg[ 7: 0];

			12: wb_dat_o <= octree_adr_reg[31:24];
			13: wb_dat_o <= octree_adr_reg[23:16];
			14: wb_dat_o <= octree_adr_reg[15: 8];
			15: wb_dat_o <= octree_adr_reg[ 7: 0];

			16:  wb_dat_o <= fb_adr_reg[31:24];
			17:  wb_dat_o <= fb_adr_reg[23:16];
			18:  wb_dat_o <= fb_adr_reg[15: 8];
			19:  wb_dat_o <= fb_adr_reg[ 7: 0];


			20:  wb_dat_o <= cache_hits_i[31:24];
			21:  wb_dat_o <= cache_hits_i[23:16];
			22:  wb_dat_o <= cache_hits_i[15: 8];
			23:  wb_dat_o <= cache_hits_i[ 7: 0];

			24:  wb_dat_o <= cache_miss_i[31:24];
			25:  wb_dat_o <= cache_miss_i[23:16];
			26:  wb_dat_o <= cache_miss_i[15: 8];
			27:  wb_dat_o <= cache_miss_i[ 7: 0];
		default: wb_dat_o <= 7'd0;
		endcase
	  end
	// --

	// = =
	always @(posedge wb_clk)
	if (wb_rst) begin
		status_reg <= 8'b0;
	end
	else begin
		if (wb_stb_i && wb_adr_i==1)
			status_reg <= 8'b0;
		else
			status_reg <= status_reg | {7'b0, rayc_finished_i};
	end
	// --

	// = Ack generation	=
	always @(posedge wb_clk)
	   if (wb_rst)
	    wb_ack_o <= 0;
	  else if (wb_ack_o)
	    wb_ack_o <= 0;
	  else if (wb_stb_i & !wb_ack_o)
	    wb_ack_o <= 1;
	// --

	assign wb_err_o = 0;
	assign wb_rty_o = 0;

endmodule
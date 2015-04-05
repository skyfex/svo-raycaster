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
		rayc_lol_o,
		ray_buf_adr_o, ray_buf_count_o, octree_adr_o, fb_adr_o,
		rayc_finished_i,

		cache_hits_i,
		cache_miss_i,

		irq_o,

		pm_o, mm_o,
		test_i
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
	output rayc_lol_o;
	output [31:0] ray_buf_adr_o;
	output [31:0] ray_buf_count_o;
	output [31:0] octree_adr_o;
	output [31:0] fb_adr_o;
	input rayc_finished_i;

	input [31:0] cache_miss_i;
	input [31:0] cache_hits_i;

	output irq_o;

	output [511:0] pm_o;
	output [511:0] mm_o;
	input [127:0] test_i;
	// --

	// = Registers =
	reg [7:0] control_reg; // 0: rayc_start
	reg [7:0] status_reg;
	reg [31:0] ray_buf_adr_reg;
	reg [31:0] ray_buf_count_reg;
	reg [31:0] octree_adr_reg;
	reg [31:0] fb_adr_reg;

	reg [31:0] pm00 = 32'hffffbae3;
	reg [31:0] pm01 = 32'h00000000;
	reg [31:0] pm02 = 32'h00000000;
	reg [31:0] pm03 = 32'h00000000;

	reg [31:0] pm10 = 32'h00000000;
	reg [31:0] pm11 = 32'hffffcc27;
	reg [31:0] pm12 = 32'h00000000;
	reg [31:0] pm13 = 32'h00000000;

	reg [31:0] pm20 = 32'h00000000;
	reg [31:0] pm21 = 32'h00000000;
	reg [31:0] pm22 = 32'h00000000;
	reg [31:0] pm23 = 32'h000033d9;

	reg [31:0] pm30 = 32'h00000000;
	reg [31:0] pm31 = 32'h00000000;
	reg [31:0] pm32 = 32'h00010000;
	reg [31:0] pm33 = 32'hfffef985;

	assign pm_o = {
		pm00, pm01, pm02, pm03,
		pm10, pm11, pm12, pm13,
		pm20, pm21, pm22, pm23,
		pm30, pm31, pm32, pm33
		};

	reg [31:0] mm00 = 32'h0000ff06;
	reg [31:0] mm01 = 32'h00000000;
	reg [31:0] mm02 = 32'h0000164f;
	reg [31:0] mm03 = 32'h00002c9f;
	reg [31:0] mm10 = 32'h00000000;
	reg [31:0] mm11 = 32'h00010000;
	reg [31:0] mm12 = 32'h00000000;
	reg [31:0] mm13 = 32'h00000000;
	reg [31:0] mm20 = 32'hffffe9b1;
	reg [31:0] mm21 = 32'h00000000;
	reg [31:0] mm22 = 32'h0000ff06;
	reg [31:0] mm23 = 32'h0000fe0d;
	reg [31:0] mm30 = 32'h00000000;
	reg [31:0] mm31 = 32'h00000000;
	reg [31:0] mm32 = 32'h00000000;
	reg [31:0] mm33 = 32'h00010000;

	assign mm_o = {
		mm00, mm01, mm02, mm03,
		mm10, mm11, mm12, mm13,
		mm20, mm21, mm22, mm23,
		mm30, mm31, mm32, mm33
		};

	// --

	// = Assignments =
	assign rayc_start_o    = control_reg[0];
	assign rayc_lol_o    = control_reg[1];
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

				20 : pm00[31:24] <= wb_dat_i;
				21 : pm00[23:16] <= wb_dat_i;
				22 : pm00[15: 8] <= wb_dat_i;
				23 : pm00[ 7: 0] <= wb_dat_i;
				24 : pm01[31:24] <= wb_dat_i;
				25 : pm01[23:16] <= wb_dat_i;
				26 : pm01[15: 8] <= wb_dat_i;
				27 : pm01[ 7: 0] <= wb_dat_i;
				28 : pm02[31:24] <= wb_dat_i;
				29 : pm02[23:16] <= wb_dat_i;
				30 : pm02[15: 8] <= wb_dat_i;
				31 : pm02[ 7: 0] <= wb_dat_i;
				32 : pm03[31:24] <= wb_dat_i;
				33 : pm03[23:16] <= wb_dat_i;
				34 : pm03[15: 8] <= wb_dat_i;
				35 : pm03[ 7: 0] <= wb_dat_i;
				36 : pm10[31:24] <= wb_dat_i;
				37 : pm10[23:16] <= wb_dat_i;
				38 : pm10[15: 8] <= wb_dat_i;
				39 : pm10[ 7: 0] <= wb_dat_i;
				40 : pm11[31:24] <= wb_dat_i;
				41 : pm11[23:16] <= wb_dat_i;
				42 : pm11[15: 8] <= wb_dat_i;
				43 : pm11[ 7: 0] <= wb_dat_i;
				44 : pm12[31:24] <= wb_dat_i;
				45 : pm12[23:16] <= wb_dat_i;
				46 : pm12[15: 8] <= wb_dat_i;
				47 : pm12[ 7: 0] <= wb_dat_i;
				48 : pm13[31:24] <= wb_dat_i;
				49 : pm13[23:16] <= wb_dat_i;
				50 : pm13[15: 8] <= wb_dat_i;
				51 : pm13[ 7: 0] <= wb_dat_i;
				52 : pm20[31:24] <= wb_dat_i;
				53 : pm20[23:16] <= wb_dat_i;
				54 : pm20[15: 8] <= wb_dat_i;
				55 : pm20[ 7: 0] <= wb_dat_i;
				56 : pm21[31:24] <= wb_dat_i;
				57 : pm21[23:16] <= wb_dat_i;
				58 : pm21[15: 8] <= wb_dat_i;
				59 : pm21[ 7: 0] <= wb_dat_i;
				60 : pm22[31:24] <= wb_dat_i;
				61 : pm22[23:16] <= wb_dat_i;
				62 : pm22[15: 8] <= wb_dat_i;
				63 : pm22[ 7: 0] <= wb_dat_i;
				64 : pm23[31:24] <= wb_dat_i;
				65 : pm23[23:16] <= wb_dat_i;
				66 : pm23[15: 8] <= wb_dat_i;
				67 : pm23[ 7: 0] <= wb_dat_i;
				68 : pm30[31:24] <= wb_dat_i;
				69 : pm30[23:16] <= wb_dat_i;
				70 : pm30[15: 8] <= wb_dat_i;
				71 : pm30[ 7: 0] <= wb_dat_i;
				72 : pm31[31:24] <= wb_dat_i;
				73 : pm31[23:16] <= wb_dat_i;
				74 : pm31[15: 8] <= wb_dat_i;
				75 : pm31[ 7: 0] <= wb_dat_i;
				76 : pm32[31:24] <= wb_dat_i;
				77 : pm32[23:16] <= wb_dat_i;
				78 : pm32[15: 8] <= wb_dat_i;
				79 : pm32[ 7: 0] <= wb_dat_i;
				80 : pm33[31:24] <= wb_dat_i;
				81 : pm33[23:16] <= wb_dat_i;
				82 : pm33[15: 8] <= wb_dat_i;
				83 : pm33[ 7: 0] <= wb_dat_i;
				84 : mm00[31:24] <= wb_dat_i;
				85 : mm00[23:16] <= wb_dat_i;
				86 : mm00[15: 8] <= wb_dat_i;
				87 : mm00[ 7: 0] <= wb_dat_i;
				88 : mm01[31:24] <= wb_dat_i;
				89 : mm01[23:16] <= wb_dat_i;
				90 : mm01[15: 8] <= wb_dat_i;
				91 : mm01[ 7: 0] <= wb_dat_i;
				92 : mm02[31:24] <= wb_dat_i;
				93 : mm02[23:16] <= wb_dat_i;
				94 : mm02[15: 8] <= wb_dat_i;
				95 : mm02[ 7: 0] <= wb_dat_i;
				96 : mm03[31:24] <= wb_dat_i;
				97 : mm03[23:16] <= wb_dat_i;
				98 : mm03[15: 8] <= wb_dat_i;
				99 : mm03[ 7: 0] <= wb_dat_i;
				100: mm10[31:24] <= wb_dat_i;
				101: mm10[23:16] <= wb_dat_i;
				102: mm10[15: 8] <= wb_dat_i;
				103: mm10[ 7: 0] <= wb_dat_i;
				104: mm11[31:24] <= wb_dat_i;
				105: mm11[23:16] <= wb_dat_i;
				106: mm11[15: 8] <= wb_dat_i;
				107: mm11[ 7: 0] <= wb_dat_i;
				108: mm12[31:24] <= wb_dat_i;
				109: mm12[23:16] <= wb_dat_i;
				110: mm12[15: 8] <= wb_dat_i;
				111: mm12[ 7: 0] <= wb_dat_i;
				112: mm13[31:24] <= wb_dat_i;
				113: mm13[23:16] <= wb_dat_i;
				114: mm13[15: 8] <= wb_dat_i;
				115: mm13[ 7: 0] <= wb_dat_i;
				116: mm20[31:24] <= wb_dat_i;
				117: mm20[23:16] <= wb_dat_i;
				118: mm20[15: 8] <= wb_dat_i;
				119: mm20[ 7: 0] <= wb_dat_i;
				120: mm21[31:24] <= wb_dat_i;
				121: mm21[23:16] <= wb_dat_i;
				122: mm21[15: 8] <= wb_dat_i;
				123: mm21[ 7: 0] <= wb_dat_i;
				124: mm22[31:24] <= wb_dat_i;
				125: mm22[23:16] <= wb_dat_i;
				126: mm22[15: 8] <= wb_dat_i;
				127: mm22[ 7: 0] <= wb_dat_i;
				128: mm23[31:24] <= wb_dat_i;
				129: mm23[23:16] <= wb_dat_i;
				130: mm23[15: 8] <= wb_dat_i;
				131: mm23[ 7: 0] <= wb_dat_i;
				132: mm30[31:24] <= wb_dat_i;
				133: mm30[23:16] <= wb_dat_i;
				134: mm30[15: 8] <= wb_dat_i;
				135: mm30[ 7: 0] <= wb_dat_i;
				136: mm31[31:24] <= wb_dat_i;
				137: mm31[23:16] <= wb_dat_i;
				138: mm31[15: 8] <= wb_dat_i;
				139: mm31[ 7: 0] <= wb_dat_i;
				140: mm32[31:24] <= wb_dat_i;
				141: mm32[23:16] <= wb_dat_i;
				142: mm32[15: 8] <= wb_dat_i;
				143: mm32[ 7: 0] <= wb_dat_i;
				144: mm33[31:24] <= wb_dat_i;
				145: mm33[23:16] <= wb_dat_i;
				146: mm33[15: 8] <= wb_dat_i;
				147: mm33[ 7: 0] <= wb_dat_i;

			endcase
		end
		else begin
			// Strobe signals reset
			control_reg[0] <= 0;
			control_reg[1] <= 0;
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

			148:  wb_dat_o <= test_i[31:24];
			149:  wb_dat_o <= test_i[23:16];
			150:  wb_dat_o <= test_i[15: 8];
			151:  wb_dat_o <= test_i[ 7: 0];
			152:  wb_dat_o <= test_i[31+32:24+32];
			153:  wb_dat_o <= test_i[23+32:16+32];
			154:  wb_dat_o <= test_i[15+32: 8+32];
			155:  wb_dat_o <= test_i[ 7+32: 0+32];
			156:  wb_dat_o <= test_i[31+64:24+64];
			157:  wb_dat_o <= test_i[23+64:16+64];
			158:  wb_dat_o <= test_i[15+64: 8+64];
			159:  wb_dat_o <= test_i[ 7+64: 0+64];
			160:  wb_dat_o <= test_i[31+96:24+96];
			161:  wb_dat_o <= test_i[23+96:16+96];
			162:  wb_dat_o <= test_i[15+96: 8+96];
			163:  wb_dat_o <= test_i[ 7+96: 0+96];

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
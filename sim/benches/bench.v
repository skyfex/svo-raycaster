`timescale 1 ns /  100 ps


module top
	(

	);

	`include "sim_params.v"

	reg clk;
	reg rst;

	reg [31:0]		wb_adr_o;
	reg [3:0]    	wb_sel_o;
	reg [31:0]		wb_dat_o;
	reg 	  			wb_we_o;
	reg 	  			wb_cyc_o;
	reg 	  			wb_stb_o;
	reg [2:0]		wb_cti_o;
	reg [1:0]		wb_bte_o;
	wire [31:0] 	wb_dat_i;
	wire 		  		wb_ack_i;
	wire 		     	wb_err_i;
	wire 		     	wb_rty_i;
	reg [31:0] clk_count2;

	sim_top dut
		(
			.wb_adr_o  (wb_adr_o),
			.wb_sel_o  (wb_sel_o),
			.wb_dat_o  (wb_dat_o),
			.wb_we_o   (wb_we_o ),
			.wb_cyc_o  (wb_cyc_o),
			.wb_stb_o  (wb_stb_o),
			.wb_cti_o  (wb_cti_o),
			.wb_bte_o  (wb_bte_o),
			.wb_dat_i  (wb_dat_i),
			.wb_ack_i  (wb_ack_i),
			.wb_err_i  (wb_err_i),
			.wb_rty_i  (wb_rty_i),

			.wb_clk(clk),
			.wb_rst(rst)
		);

	// -- Init WB --
	initial
	begin
			wb_adr_o = 0;
		 	wb_sel_o = 0;
			wb_dat_o = 0;
			wb_we_o  = 0;
			wb_cyc_o = 0;
			wb_stb_o = 0;
			wb_cti_o = 0;
			wb_bte_o = 0;
	end

	task wb_write;
		input [31:0] address;
		input [3:0] sel;
		input [31:0] data;
		begin
			`ifdef WB_DEBUG
				$display("%g Writing %h to WB adr %h", $time, data, address);
			`endif
			@(posedge clk);
			wb_adr_o = address;
			@(posedge clk);
			wb_dat_o = data;
			wb_sel_o = sel;
			wb_we_o = 1;
			wb_cyc_o = 1;
			wb_stb_o = 1;
			wb_cti_o = 0;
			wb_bte_o = 0;
			wait (wb_ack_i==1 || wb_err_i==1);
			@(posedge clk);
			if (wb_err_i==1)
				$display("wb_write: Bus error");
			else
				begin
				wb_adr_o = 32'd0;
				wb_dat_o = 32'd0;
				wb_sel_o = 4'd0;
				wb_we_o = 0;
				wb_cyc_o = 0;
				wb_stb_o = 0;
				wb_cti_o = 0;
				wb_bte_o = 0;
				end
		end
	endtask

	task wb_read;
		input [31:0] address;
		input [3:0] sel;
		output [31:0] data;

		begin
			`ifdef WB_DEBUG
				$display("%g Writing %h to WB adr %h", $time, data, address);
			`endif
			@(posedge clk);
			wb_adr_o = address;
			wb_dat_o = 0;
			wb_sel_o = sel;
			wb_we_o = 0;
			wb_cyc_o = 1;
			wb_stb_o = 1;
			wb_cti_o = 0;
			wb_bte_o = 0;
			wait (wb_ack_i==1 || wb_err_i==1);
			@(posedge clk);
			if (wb_err_i==1)
				$display("wb_read: Bus error");
			else
				begin
				data = wb_dat_i;
				wb_adr_o = 32'd0;
				wb_dat_o = 32'd0;
				wb_sel_o = 4'd0;
				wb_we_o = 0;
				wb_cyc_o = 0;
				wb_stb_o = 0;
				wb_cti_o = 0;
				wb_bte_o = 0;
				end
		end
	endtask

	task wb_bb_write_word;
		input [31:0] address;
		input [31:0] word;
		begin
		wb_write(address, 4'b1000, word);
		wb_write(address+1, 4'b0100, word);
		wb_write(address+2, 4'b0010, word);
		wb_write(address+3, 4'b0001, word);
		end
	endtask


	// -- Clock Gen --
	always
		begin
		#10 clk = ~clk;
		end

	// -- Timeout --
	initial
		begin
		#1000000000 $display("Timeout!");
		$finish;
		end

	reg [31:0] test_data;

	integer clk_count = 0;

	// -- Simulation Program --
	initial
	begin
		// -- Setup --
		$display("-- Simulation --");
		$dumpfile("bench_output.vcd");
		$dumpvars;
		clk = 0;
		rst = 0;
		#20 rst = 1;
		#20 rst = 0;
		#20;
		// -- Program --
		wb_bb_write_word(32'h9C000004, ray_data_adr); // Ray buffer address
		#20;
		wb_bb_write_word(32'h9C000008, ray_count); // Ray count
		#20;
		wb_bb_write_word(32'h9C00000C, octree_root_adr); // Octree address
		#20;
		wb_bb_write_word(32'h9C000010, framebuffer_adr); // Framebuffer address
		#20;
		clk_count = 0;
		wb_write(32'h9C000000, 4'b0001, 32'h00000001); // Start raycaster
/*		$finish;*/
	end

	always @(posedge clk)
	begin
		clk_count = clk_count+1;
		clk_count2 = clk_count;
		if (dut.rayc.raycast_slave.status_reg[0]) begin
			$display("\nDone %d %d %d %d\n", clk_count, dut.rayc.raycast_master.cache_hits, dut.rayc.raycast_master.cache_miss,
				dut.rayc.raycast_master.cache_miss*100 / (dut.rayc.raycast_master.cache_hits + dut.rayc.raycast_master.cache_miss));
/*			$display("%h", dut.rayc.irq_o); */
			wb_write(32'h9C000001, 4'b0001, {24'b0, 8'b00000001});
/*			$display("%h", dut.rayc.raycast_slave.status_reg);
			$display("%h", dut.rayc.irq_o); */

			$writememh("out.vmem", dut.xilinx_ddr2_0.ram_wb_b3_0.mem);
			$finish;
		end
	end


endmodule
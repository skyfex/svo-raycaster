

// TODO: Implement error when level overflows

`include "raycast_defines.v"

module raycast_core
	(
		clk, rst,
		start_i,

		root_adr_i,
		dir_mask_i,
		tx0_i, ty0_i, tz0_i,
		tx1_i, ty1_i, tz1_i,

	   m_wb_adr_o,  m_wb_dat_i,
		m_wb_cyc_o, m_wb_stb_o,
	   m_wb_ack_i,

		finished_o, leaf_o, t_o, level_o
	);

	// = Parameters =
	parameter dw = 32; // Data width
	parameter stack_size = 8;
	parameter stack_size_log2 = 3;
	parameter max_lvl = 32;
	parameter max_lvl_log2 = 5;

	// --

	// = Ports =
	input clk;
	input rst;
	input start_i;
	input [31:0] root_adr_i;
	input [2:0] dir_mask_i;
	input [dw-1:0] tx0_i, ty0_i, tz0_i;
	input [dw-1:0] tx1_i, ty1_i, tz1_i;

	// WISHBONE master
   output [31:0]	m_wb_adr_o;
   input [31:0]    	m_wb_dat_i;
   output       	m_wb_cyc_o;
   output       	m_wb_stb_o;
   input           	m_wb_ack_i;

	output reg finished_o;	reg finished_o_n;
	output reg leaf_o;      reg leaf_o_n;
	output [dw-1:0] t_o;
	output [max_lvl_log2-1:0] level_o;
   // --

	// = States =
	parameter S_IDLE = 0, S_INIT = 1,
		S_CALC_T = 2, S_FIRST_IDX = 3,
		S_NEXT_EVAL = 4, S_CALC_CHILD_T = 5, S_EVAL = 6, S_FINISHED = 7;
	// --

	parameter EXIT_X = 2'b01, EXIT_Y = 2'b10, EXIT_Z = 2'b00;

	// = Registers/Memories =

	reg [31:0] root_adr, root_adr_n;
	reg [2:0]  dir_mask, dir_mask_n;

	reg signed [dw-1:0] tx0_root, tx0_root_n;
	reg signed [dw-1:0] ty0_root, ty0_root_n;
	reg signed [dw-1:0] tz0_root, tz0_root_n;

	reg signed [dw-1:0] tx1_root, tx1_root_n;
	reg signed [dw-1:0] ty1_root, ty1_root_n;
	reg signed [dw-1:0] tz1_root, tz1_root_n;

	reg [2:0] 				state, 	state_n;
	reg [max_lvl_log2-1:0] 	level;

	reg [1:0]				expl_child, expl_child_n; // Child exit plane
	reg signed [dw-1:0]		t_exit_child, t_exit_child_n;
	reg signed [dw-1:0]		t_enter, t_enter_n;
	reg signed [dw-1:0] 	t_start, t_start_n;

	reg [2:0] 	idx, 				idx_n;
	reg [2:0]	idx_prev,		idx_prev_n;
	reg 		is_first_node, is_first_node_n;

	// --

	// = Wires/Aliases =
	wire signed [dw-1:0] tx0;
	wire signed [dw-1:0] ty0;
	wire signed [dw-1:0] tz0;

	wire signed [dw-1:0] txm;
	wire signed [dw-1:0] tym;
	wire signed [dw-1:0] tzm;

	wire signed [dw-1:0] tx1;
	wire signed [dw-1:0] ty1;
	wire signed [dw-1:0] tz1;

	wire signed [dw-1:0] tx1_child;
	wire signed [dw-1:0] ty1_child;
	wire signed [dw-1:0] tz1_child;

	reg tem_latch;

	wire [2:0] idx_next;
	wire exit_node;

	reg t_enter_calc;
	reg t_exit_child_calc;
	reg pass_node_calc;

	wire signed [dw-1:0] t_enter_next;
	wire signed [dw-1:0] t_exit_child_next;
	wire [1:0] expl_child_next; // Child exit plane

	// = Calculations =

	assign t_enter_next =
		(tx0>=ty0 && tx0>=tz0)	? tx0 :
		(ty0>=tz0) 				? ty0 : tz0;

	assign expl_child_next[0] =
		(tx1_child <= ty1_child) && (tx1_child <= tz1_child);

	assign expl_child_next[1] =
		!expl_child_next[0]  && (ty1_child <= tz1_child);

	assign t_exit_child_next =
		expl_child_next[0] ? tx1_child :
		expl_child_next[1] ? ty1_child : tz1_child;

	wire pass_node = (t_exit_child <= t_start);

	wire node_is_root = (level==0);
	wire [2:0] idx_flip	= idx ^ dir_mask;

	assign t_o = leaf_o ? t_enter : t_exit_child;

	// Stack signals
	reg init;
	reg push;
	reg pop;
	wire stack_empty;
	wire [2:0] idx_stack_o;

	// Master signals
	reg node_data_req;
	wire [15:0] node_data;
	wire node_data_ready;
	// Decode node data
	wire [7:0] valid_mask 		= node_data[7:0];
	wire [7:0] leaf_mask 		= node_data[15:8];

	wire child_is_solid = leaf_mask[idx_flip];
	wire child_is_valid = valid_mask[idx_flip];

	// --

	// = Datapath Instances =
	raycast_core_axis_dp x_axis_dp
		(
			.clk       (clk),
			.rst       (rst),
			.init_i    (init),
			.push_i    (push),
			.pop_i     (pop),
			.tem_latch_i (tem_latch),
			.idx_i 	  (idx[2]),
			.idx_prev_i (idx_prev[2]),
			.te0_i     (tx0_root),
			.te1_i     (tx1_root),
			.te0_o     (tx0),
			.tem_o     (txm),
			.te1_o     (tx1),
			.te1_child_o (tx1_child)
		);
	defparam x_axis_dp.dw = dw;
	defparam x_axis_dp.stack_size = stack_size+1;

	raycast_core_axis_dp y_axis_dp
		(
			.clk       (clk),
			.rst       (rst),
			.init_i    (init),
			.push_i    (push),
			.pop_i     (pop),
			.tem_latch_i (tem_latch),
			.idx_i (idx[1]),
			.idx_prev_i (idx_prev[1]),

			.te0_i     (ty0_root),
			.te1_i     (ty1_root),
			.te0_o     (ty0),
			.tem_o     (tym),
			.te1_o     (ty1),
			.te1_child_o (ty1_child)
		);
	defparam y_axis_dp.dw = dw;
	defparam y_axis_dp.stack_size = stack_size+1;

	raycast_core_axis_dp z_axis_dp
		(
			.clk       (clk),
			.rst       (rst),
			.init_i    (init),
			.push_i    (push),
			.pop_i     (pop),
			.tem_latch_i (tem_latch),

			.idx_i (idx[0]),
			.idx_prev_i (idx_prev[0]),

			.te0_i     (tz0_root),
			.te1_i     (tz1_root),
			.te0_o     (tz0),
			.tem_o     (tzm),
			.te1_o     (tz1),
			.te1_child_o (tz1_child)
		);
	defparam z_axis_dp.dw = dw;
	defparam z_axis_dp.stack_size = stack_size+1;


	raycast_core_idx idx_next_dp
		(
			.is_first_i (is_first_node),
			.idx_i (idx),
			.txm_i (txm),
			.tym_i (tym),
			.tzm_i (tzm),
			.t_enter_i (t_enter),
			.exit_plane_child_i (expl_child),

			.idx_next_o(idx_next),
			.is_exit_o(exit_node)
		);
	defparam idx_next_dp.dw = dw;

	raycast_core_master core_master
		(
			.clk                (clk),
			.rst                (rst),
		   .m_wb_adr_o          (m_wb_adr_o),
			.m_wb_dat_i         (m_wb_dat_i),
			.m_wb_cyc_o         (m_wb_cyc_o),
			.m_wb_stb_o         (m_wb_stb_o),
		   .m_wb_ack_i          (m_wb_ack_i),
			.init_i             (init),
			.pop_i              (pop),
			.root_adr_i         (root_adr),
			.idx_flip_i         (idx_flip),
			.node_data_req_i    (node_data_req),
			.node_data_ready_o  (node_data_ready),
			.node_data_o        (node_data)
		);
	defparam core_master.stack_size = stack_size;
	defparam core_master.stack_size_log2 = stack_size_log2;

	// --

	// = Control FSM =
	always @(*)
	begin
		root_adr_n = root_adr;
		dir_mask_n = dir_mask;
		tx0_root_n = tx0_root;
		ty0_root_n = ty0_root;
		tz0_root_n = tz0_root;
		tx1_root_n = tx1_root;
		ty1_root_n = ty1_root;
		tz1_root_n = tz1_root;

		state_n = state;

		expl_child_n = expl_child;
		t_exit_child_n = t_exit_child;
		t_enter_n = t_enter;
		t_start_n = t_start;

		idx_prev_n = idx_prev;
		idx_n = idx;
		is_first_node_n = is_first_node;

		leaf_o_n = leaf_o;
		finished_o_n = finished_o;

		t_enter_calc = 0;
		t_exit_child_calc = 0;
		pass_node_calc = 0;
		tem_latch = 0;

		init = 0;
		push = 0;
		pop = 0;
		node_data_req = 0;

		case (state)
			S_IDLE: begin // 0
				if (start_i) begin
					root_adr_n = root_adr_i;
					dir_mask_n = dir_mask_i;
					tx0_root_n = tx0_i;
					ty0_root_n = ty0_i;
					tz0_root_n = tz0_i;
					tx1_root_n = tx1_i;
					ty1_root_n = ty1_i;
					tz1_root_n = tz1_i;
					t_start_n  = 0;
					finished_o_n = 0;
					state_n = S_INIT;
				end
			end
			S_INIT: begin // 1

				// Fetch root data
				// Set level = 0
				// Reset stack
				init = 1;
				is_first_node_n = 1;
				state_n = S_CALC_T;
			end
			S_CALC_T: begin // 2
				// tm <= (t0+t1)/2 (in axis_dp)
				tem_latch = 1;

				// t_enter <= min(t0)
				t_enter_calc = 1;
				t_enter_n = t_enter_next;

				if (is_first_node)
					state_n = S_FIRST_IDX;
				else
					state_n = S_NEXT_EVAL;
			end
			S_FIRST_IDX: begin // 3
				if (node_data_ready) begin
					idx_n = idx_next;
					is_first_node_n = 0;
					state_n = S_CALC_CHILD_T;
				end
			end
			S_NEXT_EVAL: begin
				if (exit_node) begin
					// We've exited current octant.
					if (node_is_root) begin
						// Exited octree, we're finished
						leaf_o_n = 0;
						state_n = S_FINISHED;
					end
					else if (stack_empty) begin
						// Stack underflow, restart from root
						t_start_n = t_exit_child;
						state_n = S_INIT;
					end
`ifndef RAYC_DISABLE_STACK
					else begin
						// Go up a level. Pop the stack.
						pop = 1;
						idx_prev_n = idx_stack_o;
						idx_n = idx_prev;
						state_n = S_CALC_T;
					end
`endif
				end
				else begin
					idx_n = idx_next;
					state_n = S_CALC_CHILD_T;
				end
			end
			S_CALC_CHILD_T: begin
				t_exit_child_calc = 1;
				t_exit_child_n = t_exit_child_next;
				expl_child_n = expl_child_next;
				state_n = S_EVAL;
			end
			S_EVAL: begin
				pass_node_calc = 1;
				if (pass_node) begin
					// Proceed to next child voxel
					state_n = S_NEXT_EVAL;
				end
				else if (child_is_solid)	begin
					// We hit a voxel
					// Push to get child parameters
					push = 1;
					leaf_o_n = 1;
					state_n = S_FINISHED;
				end
				else if (child_is_valid) begin
					// We hit an octant containing something
					// Push and get next node
					// level <= level+1
					push = 1;
					idx_prev_n = idx;
					is_first_node_n = 1;
					node_data_req = 1;

					state_n = S_CALC_T;
				end
				else begin
					// Empty octant, evaluate next child node
					state_n = S_NEXT_EVAL;
				end
			end
			S_FINISHED: begin
				// Calculate t_enter for child
				t_enter_calc = 1;
				t_enter_n = t_enter_next;

				finished_o_n = 1;
				state_n = S_IDLE;
			end

		endcase
	end
	// --

	// = Registers =

	always @(posedge clk)
	begin
		if (rst) begin
			root_adr <= 32'd0;
			dir_mask <= 3'd0;
			tx0_root <= 32'd0;
			ty0_root <= 32'd0;
			tz0_root <= 32'd0;
			tx1_root <= 32'd0;
			ty1_root <= 32'd0;
			tz1_root <= 32'd0;
			state    <= 3'd0;
			level    <= 0;
			expl_child <= 2'd0;
			t_exit_child <= 32'd0;
			t_enter <= 32'd0;
			t_start  <= 32'd0;
			idx_prev	<= 3'd0;
			idx      <= 3'd0;
			is_first_node <= 0;
			finished_o <= 1;
			leaf_o <= 0;
		end
		else
		begin
			root_adr	<=	root_adr_n;
			dir_mask	<=	dir_mask_n;

			tx0_root	<=	tx0_root_n;
			ty0_root	<=	ty0_root_n;
			tz0_root	<=	tz0_root_n;

			tx1_root	<=	tx1_root_n;
			ty1_root	<=	ty1_root_n;
			tz1_root	<=	tz1_root_n;

			state	<=	state_n;

			expl_child <= expl_child_n;
			t_exit_child <= t_exit_child_n;
			t_enter <= t_enter_n;
			t_start	<=	t_start_n;

			idx	<=	idx_n;
			idx_prev <= idx_prev_n;
			is_first_node	<=	is_first_node_n;

			finished_o <= finished_o_n;
			leaf_o <= leaf_o_n;

			if (init)
				level <= 0;
			else if (push)
				level <= level + 1;
			else if (pop)
				level <= level - 1;
			else
				level <= level;
		end
	end


	// --

	// = Stacks =
`ifndef RAYC_DISABLE_STACK

	reg [stack_size_log2:0] stack_depth;
	wire stack_full = (stack_depth==stack_size);
	assign stack_empty = (stack_depth==0);


	always @(posedge clk)
		if (init) begin
			stack_depth <= 0;
		end
		else if (push) begin
			if (!stack_full)
				stack_depth <= stack_depth + 1;
		end
		else if (pop) begin
			stack_depth <= stack_depth - 1;
		end

	raycast_stack idx_stack_inst
		(
			.clk (clk),
			.push (push),
			.pop (pop),
			.data_i (idx_prev),
			.data_o (idx_stack_o)
		);
		defparam idx_stack_inst.dw = 3;
		defparam idx_stack_inst.depth = stack_size; ///-1
		defparam idx_stack_inst.depth_log2 = stack_size_log2;
`else
	assign stack_empty = 1;
`endif
	// --


endmodule
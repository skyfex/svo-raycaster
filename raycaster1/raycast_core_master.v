
`include "raycast_defines.v"

module raycast_core_master
	(
		clk, rst,

		// WB Master
		m_wb_adr_o,  m_wb_dat_i,
		m_wb_cyc_o, m_wb_stb_o,
		m_wb_ack_i,

		init_i, pop_i,
		root_adr_i,
		idx_flip_i,
		node_data_req_i,
		node_data_ready_o,
		node_data_o

	);

	// = Parameters =
	parameter stack_size = 2;
	parameter stack_size_log2 = 1;
	// --

	// = Ports =
	input clk;
	input rst;

	// WISHBONE master
	output reg [31:0]		m_wb_adr_o;
	input [31:0]    		m_wb_dat_i;
	output reg       		m_wb_cyc_o;
	output		       		m_wb_stb_o;
	input           		m_wb_ack_i;

	input init_i;
	input pop_i;
	input [31:0] root_adr_i;
	input [2:0] idx_flip_i;
	input node_data_req_i;

	output  node_data_ready_o;
	output [15:0] node_data_o;

	// --

	// = Parameters =
	parameter S_IDLE = 0, S_FAR_WAIT = 1, S_FAR_RESOLVE = 2, S_FAR_FINAL = 3,
		 S_NODE_READ = 4, S_RESOLVE = 5;
	// --

	// = Registers =
	reg [2:0] state;

	reg [31:0] node_data;
	reg [31:0] node_adr;
	reg node_adr_resolved;

	reg [31:0] far_reg;
	// --

	// = Wires/expressions =
	wire [7:0] valid_mask 		= node_data[7:0];
	wire [7:0] leaf_mask 		= node_data[15:8];
	wire [14:0] child_ptr 		= node_data[30:16];
	wire child_ptr_far 			= node_data[31];

	wire [7:0] is_node_mask		= valid_mask & ~leaf_mask;
	reg [3:0] child_offsets [0:7];

	wire [31:0] node_adr_stack_o;
	wire [15:0] node_data_stack_o;

	wire push_stack = (state==S_NODE_READ && m_wb_ack_i);

	assign node_data_ready_o = (state==S_IDLE);
	assign node_data_o = node_data[15:0];
	assign m_wb_stb_o = m_wb_cyc_o;
	// --


	always @(posedge clk)
	begin
		if (rst) begin
			state <= S_IDLE;

		end
		else begin
			case (state)
				S_IDLE: begin
					if (init_i) begin
						node_adr <= root_adr_i;
						m_wb_adr_o <= root_adr_i;
						node_adr_resolved <= 0;
						m_wb_cyc_o <= 1;
						state <= S_NODE_READ;
					end
					else if (pop_i) begin
						node_data[15:0] <= node_data_stack_o;
						node_adr <= node_adr_stack_o;
						node_adr_resolved <= 1;
						state <= S_IDLE;
					end
					else if (node_data_req_i) begin
						if (node_adr_resolved) begin
							m_wb_adr_o <= node_adr + {27'b0, child_offsets[idx_flip_i], 2'b0};
							m_wb_cyc_o <=  1;
							state <= S_NODE_READ;
						end else
						begin
							m_wb_adr_o <= far_reg;
							m_wb_cyc_o <=  1;
							state <= S_FAR_WAIT;
						end
					end
				end
				S_FAR_WAIT: begin
					if (m_wb_ack_i) begin
						m_wb_cyc_o <= 0;
						far_reg <= {m_wb_dat_i[29:0],2'b0};
						state <= S_FAR_RESOLVE;
					end
				end
				S_FAR_RESOLVE: begin
					node_adr <= node_adr + far_reg;
					state <= S_FAR_FINAL;
				end
				S_FAR_FINAL: begin
					m_wb_adr_o <= node_adr + {27'b0, child_offsets[idx_flip_i], 2'b0};
					m_wb_cyc_o <=  1;
					state <= S_NODE_READ;
				end
				S_NODE_READ: begin
					if (m_wb_ack_i) begin
						// Note: stack push_stack is triggered here
						m_wb_cyc_o <= 0;
						node_adr_resolved <= 0;
						node_adr <= m_wb_adr_o;
						node_data <= m_wb_dat_i;
						state <= S_RESOLVE;
					end
				end
				S_RESOLVE: begin
					if (child_ptr_far) begin
						far_reg <= node_adr + {15'b0, child_ptr, 2'b0};
					end else
					begin
						node_adr <= node_adr + {15'b0, child_ptr, 2'b0};
						node_adr_resolved <= 1;
					end
					state <= S_IDLE;
				end
			endcase
		end
	end


`ifndef RAYC_DISABLE_STACK


	// = Stacks =
	raycast_stack node_adr_stack_inst
		(
			.clk (clk),
			.push (push_stack),
			.pop (pop_i),
			.data_i (node_adr),
			.data_o (node_adr_stack_o)
		);
		defparam node_adr_stack_inst.dw = 32;
		defparam node_adr_stack_inst.depth = stack_size;
		defparam node_adr_stack_inst.depth_log2 = stack_size_log2;

	raycast_stack node_data_stack_inst
		(
			.clk (clk),
			.push (push_stack),
			.pop (pop_i),
			.data_i (node_data[15:0]),
			.data_o (node_data_stack_o)
		);
		defparam node_data_stack_inst.dw = 16;
		defparam node_data_stack_inst.depth = stack_size;
		defparam node_data_stack_inst.depth_log2 = stack_size_log2;
	// --

`endif

	// = Child offset decoder =
	always @(is_node_mask)
	begin
		child_offsets[0] = 3'b0;
		child_offsets[1] = {2'b0, is_node_mask[0]};
		child_offsets[2] = child_offsets[1] + {2'b0, is_node_mask[1]};
		child_offsets[3] = child_offsets[2] + {2'b0, is_node_mask[2]};
		child_offsets[4] = child_offsets[3] + {2'b0, is_node_mask[3]};
		child_offsets[5] = child_offsets[4] + {2'b0, is_node_mask[4]};
		child_offsets[6] = child_offsets[5] + {2'b0, is_node_mask[5]};
		child_offsets[7] = child_offsets[6] + {2'b0, is_node_mask[6]};

	end
	// --


endmodule
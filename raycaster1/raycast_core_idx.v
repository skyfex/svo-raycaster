
module raycast_core_idx
	(
		is_first_i, idx_i,
		txm_i, tym_i, tzm_i,
		t_enter_i,
		exit_plane_child_i,
		
		idx_next_o,
		is_exit_o,
	);
	
	// = Parameters =
	parameter dw = 32; // Data width
	// --
	
	// = Ports =
	input is_first_i;
	input [2:0]idx_i;
	
	input signed [dw-1:0] txm_i, tym_i, tzm_i;
	input signed [dw-1:0] t_enter_i;
	input [1:0] exit_plane_child_i;
	
	output reg [2:0]idx_next_o;
	output reg is_exit_o;
	// --
	
	// = Wires =

								
	// --
	
	always @(is_first_i, idx_i, txm_i, tym_i, tzm_i, t_enter_i, exit_plane_child_i)
	begin
		is_exit_o = 0;
		if (is_first_i) begin
			idx_next_o <= {txm_i < t_enter_i, tym_i < t_enter_i, tzm_i < t_enter_i};
		end
		else begin
			if (exit_plane_child_i[0]) begin
				idx_next_o <= idx_i ^ 3'b100;
				is_exit_o = idx_i[2];
			end
			else if (exit_plane_child_i[1]) begin
				idx_next_o <= idx_i ^ 3'b010;
				is_exit_o = idx_i[1];
			end
			else begin
				idx_next_o <= idx_i ^ 3'b001;
				is_exit_o = idx_i[0];
			end
		end
	end
		
endmodule
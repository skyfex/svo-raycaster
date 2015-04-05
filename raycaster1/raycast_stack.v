
module raycast_stack
	(
		clk,
		push, pop,
		data_i, data_o
/*		done*/
	);

	// = Parameters =
	parameter dw = 32;
	parameter depth = 8;
	parameter depth_log2 = 3;
	// --

	// = Ports =
	input clk;

	input push;
	input pop;

	input [dw-1:0] data_i;
	output [dw-1:0] data_o;

/*	output done;*/
	// --

	// = Memories =
	reg [dw-1:0] stack_data[0:depth-1];
	reg [depth_log2-1:0] stack_ptr = 0;
	// --

	// -- Shift-register based stack --
	// assign data_o = stack_data[0];
	// integer i;
	// always @(posedge clk)
	// begin
	// 	if (push) begin
	// 		for (i=1;i<depth;i=i+1) begin
	// 			stack_data[i] <= stack_data[i-1];
	// 		end
	// 		stack_data[0] <= data_i;
	// 	end
	// 	else if (pop) begin
	// 		for (i=1;i<depth;i=i+1) begin
	// 			stack_data[i-1] <= stack_data[i];
	// 		end
	// 	end
	// end

	// -- Memory based stack --
	// We trust this operation to wrap around depth
	wire [depth_log2-1:0] stack_ptr_inc = stack_ptr + 1;
	wire [depth_log2-1:0] stack_ptr_dec = stack_ptr - 1;
	assign data_o = stack_data[stack_ptr];
	always @(posedge clk)
	begin
		if (push) begin
			stack_data[stack_ptr_inc] <= data_i;
			stack_ptr <= stack_ptr_inc;
		end
		else if (pop) begin
			stack_ptr <= stack_ptr_dec;
		end
	end



endmodule
`timescale 1 ns /  100 ps


module top 
	(
	
	);
		
	
	reg clk;
	reg rst;
	
	reg start_i                ;
	reg [31:0] ray_adr_i       ;
	reg [31:0] root_adr_i      ;
	reg [2:0] dir_mask_i       ;
	reg [31:0] tx0_i           ;
	reg [31:0] ty0_i           ;
	reg [31:0] tz0_i           ;
	reg [31:0] tx1_i           ;
	reg [31:0] ty1_i           ;
	reg [31:0] tz1_i           ;
	wire node_req_o            ;
	wire node_req_far_o        ;
	wire [31:0] node_req_adr_o ;
	reg node_ack_i             ;
	reg [31:0] node_data_i     ;
	reg [31:0] node_adr_i      ;
	wire finished_o;
	
	// = Core =
	raycast_core dut
		(                                    
			.clk 					 (clk           ),
			.rst               (rst           ),
			.start_i           (start_i       ),
			.ray_adr_i         (ray_adr_i     ),
			.root_adr_i        (root_adr_i    ),
			.dir_mask_i        (dir_mask_i    ),
			.tx0_i             (tx0_i         ),
			.ty0_i             (ty0_i         ),
			.tz0_i             (tz0_i         ),
			.tx1_i             (tx1_i         ),
			.ty1_i             (ty1_i         ),
			.tz1_i             (tz1_i         ),
			.node_req_o        (node_req_o    ),
			.node_req_far_o    (node_req_far_o), 
			.node_req_adr_o    (node_req_adr_o),
			.node_ack_i        (node_ack_i    ),
			.node_data_i       (node_data_i   ),
			.node_adr_i        (node_adr_i    ),
			.finished_o			 (finished_o	 )
		);
		
		
	
	// -- Clock Gen --
	always
		#10 clk = ~clk;
		
	// -- Timeout --
	initial
		begin
		#10000 $display("Timeout!");
		$finish;
		end
		
	
	// -- Simulation Program --
	initial
	begin
		// -- Setup --
		$display("-- Simulation --");
		$dumpfile("bench_core_output.vcd");
		$dumpvars;
		clk = 0;
		rst = 0;
		#20 rst = 1;
		#20 rst = 0;
		#20;
		// -- Program --

		$finish;
	end
	
	
endmodule
`timescale 1 ns /  100 ps


module bench 
	(
	
	);
		
	
	reg clk;
	reg rst;

	// ORLINK interface
	reg ifclk_in;
	reg fifoData_wr;
	reg [7:0] fifoData_out;
	wire [7:0] fifoData_io;
	reg gotData_in;
	reg gotRoom_in;
	
	output sloe_out;     
	output slrd_out;    
	output slwr_out;
	output [1:0] fifoAddr_out;
	output pktEnd_out;
	
	wire [7:0] led;

	assign fifoData_io = fifoData_wr ? fifoData_out : 8'bz;
	
	orlink dut
		(
			.wb_rst(rst),
			.wb_clk(clk),

			.ifclk_in(ifclk_in),
			.fifoData_io(fifoData_io),
			.gotData_in(gotData_in),
			.gotRoom_in(gotRoom_in),

			.sloe_out(sloe_out),     
			.slrd_out(slrd_out),    
			.slwr_out(slwr_out),   
			.fifoAddr_out(fifoAddr_out), 
			.pktEnd_out(pktEnd_out)

		);
		
	initial
		begin
		gotData_in = 0;
		gotRoom_in = 0;
		fifoData_wr = 0;
		fifoData_out = 8'b0;
		end 

	// write single byte
	task com_write;
		input [7:0] address;
		input [7:0] data;
		integer i;
		begin
			wait(slrd_out==0);
			@(posedge ifclk_in); #1;
			fifoData_wr = 1;
			fifoData_out = address & 8'b01111111;
			gotData_in = 1;
			@(posedge ifclk_in); #1;
			fifoData_out = 0;
			@(posedge ifclk_in); #1;
			fifoData_out = 0;
			@(posedge ifclk_in); #1;
			fifoData_out = 0;
			@(posedge ifclk_in); #1;
			fifoData_out = 1;
			@(posedge ifclk_in); #1;
			fifoData_out = data;
			wait(slrd_out==0);
			@(posedge ifclk_in); #1;
			gotData_in = 0;
			fifoData_wr = 0;
			fifoData_out = 0;
		end
	endtask		
	
	task com_write_file;
		input [7:0] address;
		input [31:0] count;
		reg [7:0] data[0:10];
		integer i;
		begin
			$readmemh("writedata.txt", data);
			wait(slrd_out==0);
			@(posedge ifclk_in); #1;
			fifoData_wr = 1;
			fifoData_out = address & 8'b01111111;
			gotData_in = 1;
			@(posedge ifclk_in); #1;
			fifoData_out = count[31:24];
			@(posedge ifclk_in); #1;
			fifoData_out = count[23:16];
			@(posedge ifclk_in); #1;
			fifoData_out = count[15:8];
			@(posedge ifclk_in); #1;
			fifoData_out = count[7:0];
			
			@(posedge ifclk_in); #1;
			i=0;
			while (i<count) begin
				fifoData_out = data[i];
				@(posedge ifclk_in);
				if (slrd_out==0)
					i=i+1;
				 #1;
			end
			gotData_in = 0;
			fifoData_wr = 0;
			fifoData_out = 0;
			@(posedge ifclk_in); #1;
			
		end
	endtask
	
	task com_read;
		input [7:0] address;
		input [31:0] count;
		integer i;
		begin
			@(posedge ifclk_in); #1;
			fifoData_wr = 1;
			fifoData_out = address | 8'b10000000;
			gotData_in = 1;
			@(posedge ifclk_in); #1;
			fifoData_out = count[31:24];
			@(posedge ifclk_in); #1;
			fifoData_out = count[23:16];
			@(posedge ifclk_in); #1;
			fifoData_out = count[15:8];
			@(posedge ifclk_in); #1;
			fifoData_out = count[7:0];
			@(posedge ifclk_in); #1;
			fifoData_wr = 0;
			gotData_in = 0;
			gotRoom_in = 1;
			i=0;
			while (i<count) begin
				@(posedge ifclk_in); 
				if (slwr_out==0) begin
					$display("%h", fifoData_io);
					i=i+1;
				end
				#1;
			end
			gotRoom_in = 0;
			gotData_in = 0;
			fifoData_wr = 0;
			fifoData_out = 0;
			@(posedge ifclk_in); #1;
			
		end
	endtask
			
	
	// -- Clock Gen --
	always
		#20 clk = ~clk;
	
	always
		#10 ifclk_in = ~ifclk_in;
		
	// -- Timeout --
	initial
		begin
		#1000000 $display("Timeout!");
		$finish;
		end
		
/*	reg [7:0] test_data [256];
	test_data = {{8'b0, 8'b1}};*/
	
/*	wire [31:0] mem_extract0 = dut.xilinx_ddr2_0.ram_wb_b3_0.mem[0];
	wire [31:0] mem_extract1 = dut.xilinx_ddr2_0.ram_wb_b3_0.mem[1];
	*/
	// -- Simulation Program --
	initial
	begin
		// -- Setup --
		$display("-- Simulation --");
		$dumpfile("output.vcd");
		$dumpvars;
		ifclk_in = 0;
		clk = 0;
		rst = 0;
		#40 rst = 1;
		#40 rst = 0;
		#40;
		// -- Program --
		com_write(8'h00, 8'h13);
		com_read(8'h00, 1);
		
/*		com_write(8'h01, 8'h00);
		com_write(8'h02, 8'h00);
		com_write(8'h03, 8'h00);
		com_write(8'h04, 8'h00);

		com_write_file(8'h05, 10);
						
		com_write(8'h01, 8'h00);
		com_write(8'h02, 8'h00);
		com_write(8'h03, 8'h00);
		com_write(8'h04, 8'h00);
		com_read(8'h06, 10);*/
		#40;
		$finish;
	end
	
	
endmodule
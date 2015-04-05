module test
	(
	);
	
/*	reg test;*/
	
	reg [2:0] a;
	reg [2:0] b;
	wire [3:0] c;
	
	assign c = a+b;
	
	
initial
	begin
	#10;
	a <= 3'b111;
	b <= 3'b010;
	#1
	$display("%b", c);
	end
endmodule
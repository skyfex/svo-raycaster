module orlink_crc16(clk, rst, en, din, dout);

input clk rst, en;
input [7:0] din;
output [15:0] dout;

wire [15:0] xor_out;
reg [15:0] r;
wire [15:0] temr;

assign temr[0] = din[4]  ^ din[0];
assign temr[1] = din[5]  ^ din[1];
assign temr[2] = din[6]  ^ din[2];
assign temr[3] = din[7]  ^ din[3];
assign temr[4] = din[12] ^ r[8];
assign temr[5] = din[13] ^ r[9];
assign temr[6] = din[14] ^ r[10];
assign temr[7] = din[15] ^ r[11];
assign temr[8] = din[4]  ^ r[12];
assign temr[9] = din[5]  ^ r[13];
assign temr[10] = din[6] ^ r[14];
assign temr[11] = din[7] ^ r[15];
assign temr[12] = temr[0] ^ temr[4];
assign temr[13] = temr[1] ^ temr[5];
assign temr[14] = temr[2] ^ temr[6];
assign temr[15] = temr[3] ^ temr[7];


assign xor_out[0] =  temr[12];
assign xor_out[1] =  temr[13];
assign xor_out[2] =  temr[14];
assign xor_out[3] =  temr[15];
assign xor_out[4] =  temr[8];
assign xor_out[5] =  temr[9]  ^ temr[12];
assign xor_out[6] =  temr[10] ^ temr[13];
assign xor_out[7] =  temr[11] ^ temr[14];
assign xor_out[8] =  temr[15] ^ r[0];
assign xor_out[9] =  temr[8]  ^ r[1];
assign xor_out[10] = temr[9]  ^ r[2];
assign xor_out[11] = temr[10] ^ r[3];
assign xor_out[12] = temr[11] ^ temr[12] ^ r[4];
assign xor_out[13] = temr[13] ^ r[5];
assign xor_out[14] = temr[14] ^ r[6];
assign xor_out[15] = temr[15] ^ r[7];

always @(posedge clk)
begin
	if (rst)
		r <= 0;
	else begin
		if (en)
			r <= xor_out;
	end
end

assign dout = r;

endmodule

`timescale 1 ns/1 ps

module multiplier (
  clk, a, b, p
)/* synthesis syn_black_box syn_noprune=1 */;
  input clk;
  input signed [31 : 0] a;
  input signed [31 : 0] b;
  output signed [63 : 0] p;


 wire signed [63:0] result = a*b;

 reg  signed [63:0] pipeline[1:4];

  always @(posedge clk)
  begin
    pipeline[1] <= result;
    pipeline[2] <= pipeline[1];
    pipeline[3] <= pipeline[2];
    pipeline[4] <= pipeline[3];
  end

  assign p = pipeline[4];

endmodule

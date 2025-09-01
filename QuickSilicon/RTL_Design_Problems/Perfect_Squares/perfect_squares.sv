module perfect_squares (
  input   logic        clk,
  input   logic        reset,

  output  logic [31:0] sqr_o
);

  logic [31:0] cntr_q;
  logic [31:0] nxt_cntr;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      cntr_q <= 32'h3;
    else
      cntr_q <= nxt_cntr;

  assign nxt_cntr = cntr_q + 32'h2;

  logic [31:0] ps_num_q;
  logic [31:0] nxt_ps_num;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      ps_num_q <= 32'h1;
    else
      ps_num_q <= nxt_ps_num;

  assign nxt_ps_num = ps_num_q + cntr_q;

  assign sqr_o = nxt_ps_num;

endmodule

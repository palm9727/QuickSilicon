module one_shot (
  input   logic        clk,
  input   logic        reset,

  input   logic        data_i,

  output  logic        shot_o

);

  // data register logic
  logic data_q;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      data_q <= 1'b0;
    else
      data_q <= data_i;

  assign shot_o = (data_i) ? ((~data_q) ? 1'b1: 1'b0) : 1'b0;

endmodule

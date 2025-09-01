// System used to detect a 3 bit palindrome given as a serial input

module palindrome3b (
  input   logic        clk,
  input   logic        reset,

  input   logic        x_i,

  output  logic        palindrome_o
);

  // Register logic
  logic [1:0] num_q;
  logic [2:0] num;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      num_q <= 2'h0;
    else
      num_q <= num[1:0];

  assign num = {num_q, x_i};

  // Counter logic
  logic [1:0] cnt;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      cnt <= 2'h0;
    else if (cnt < 2'h2)
      cnt <= cnt + 2'h1;

  // Output logic
  assign palindrome_o = (num[2] == num[0]) ? (cnt[1] ? 1'b1 : 1'b0) : 1'b0;

endmodule
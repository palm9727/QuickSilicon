// This module gives the correct outputs for the palindrome but does not pass the testbench
// even when all signals are correct.

module palindrome3b (
  input   logic        clk,
  input   logic        reset,

  input   logic        x_i,

  output  logic        palindrome_o
);

  // 3 bit palindrome register
  logic [2:0] num;
  logic [1:0] num_q;

  always_ff @(posedge clk or posedge reset)
    num_q <= num[1:0];

  assign num = {num_q, x_i};

  // Allow output signal logic
  logic[4:0] allow_o;

  always_ff @(posedge clk or posedge reset) begin
    allow_o <= {allow_o[3:0], 1'b1};
  end

  // Palindrome output logic
  always_comb begin
    palindrome_o = 1'b0;
    if ((num == 3'b000 || num == 3'b010 || num == 3'b101 || num == 3'b111) && (allow_o[4]))
      palindrome_o = 1'b1;
  end

endmodule

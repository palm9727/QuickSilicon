// System used to check if a number created by the serial input is divisible by 3

module div_by_three (
  input   logic    clk,
  input   logic    reset,

  input   logic    x_i,

  output  logic    div_o

);

  // Register logic for the number to divide
  logic[63:0] num;
  logic [62:0] num_q;

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      num_q <= 63'h0;
    else
      num_q <= num[62:0];
  end

  assign num = {num_q, x_i};

  // Divisible by 3 output logic
  always_comb begin
    div_o = 1'b0;
    if ((num == 64'h0) || (num % 3 == 0))
      div_o = 1'b1;
  end

endmodule

// Detecting a big sequence - 1110_1101_1011
module sequence_detector (
  input     wire        clk,
  input     wire        reset,
  input     wire        x_i,

  output    wire        det_o
);

  // Input register logic
  logic[11:0] i;
  logic[11:0] i_q;

  always_comb begin
    i = {i_q[10:0], x_i};
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      i_q <= 0;
    end else begin
      i_q <= i;
    end
  end

  // Output logic
  assign det_o = (i_q == 12'b111011011011) ? 1'b1 : 1'b0;

endmodule

// Linear Feedback Shift Register Implementation

module lfsr (
  input     wire      clk,
  input     wire      reset,

  output    wire[3:0] lfsr_o
);

  // LFSR signals
  logic[3:0] lfsr_d;
  logic[3:0] lfsr_q;

  // LFSR Combinational Logic
  always_comb begin
    lfsr_d = 4'h0;

    if (reset) begin
      lfsr_d = 4'b1000;
    end else begin
      lfsr_d = {lfsr_q[2:0], (lfsr_q[3] ^ lfsr_q[1])};
    end
  end

  // LFSR Sequential Logic
  always_ff @(posedge clk) begin
    lfsr_q <= lfsr_d;
  end

  // Synchronous output
  assign lfsr_o = lfsr_q;

endmodule

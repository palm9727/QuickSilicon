// Simple shift register
module shift_register(
  input     wire        clk,
  input     wire        reset,
  input     wire        x_i,      // Serial input

  output    wire[3:0]   sr_o
);

  // Shift register signals
  logic[3:0] sr_d;
  logic[3:0] sr_q;

  // Combinational logic for the shift register
  always_comb begin
    sr_d = 4'h0;

    if (reset) begin
      sr_d = 4'h0;
    end else begin
      sr_d = {sr_q[2:0], x_i};
    end
  end

  // Sequential logic for the shift register
  always_ff @(posedge clk) begin
    sr_q <= sr_d;
  end

  // Output signal logic
  assign sr_o = sr_q;

endmodule

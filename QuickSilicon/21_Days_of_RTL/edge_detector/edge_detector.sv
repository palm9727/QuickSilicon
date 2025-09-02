 // A rising and falling edge detector

module edge_detector (
  input     wire    clk,
  input     wire    reset,

  input     wire    a_i,

  output    wire    rising_edge_o,
  output    wire    falling_edge_o
);

  // Logic for the input register signal
  logic a_reg;

  always_ff @(posedge clk) begin
    a_reg <= a_i;
  end

  // Logic for the rising and falling edge outputs
  logic rising_edge_q;
  logic falling_edge_q;

  always_ff @(posedge clk) begin
    if (reset) begin
      rising_edge_q <= 1'b0;
      falling_edge_q <= 1'b0;
    end else begin
      if (~a_reg && a_i) begin
        rising_edge_q <= 1'b1;
      end else begin
        rising_edge_q <= 1'b0;
      end

      if (a_reg && ~a_i) begin
        falling_edge_q <= 1'b1;
      end else begin
        falling_edge_q <= 1'b0;
      end
    end
  end

  assign rising_edge_o = rising_edge_q;
  assign falling_edge_o = falling_edge_q;

endmodule

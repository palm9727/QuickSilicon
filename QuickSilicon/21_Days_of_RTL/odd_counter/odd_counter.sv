// Odd counter

module odd_counter (
  input     wire        clk,
  input     wire        reset,

  output    logic[7:0]  cnt_o
);

  // Counter signals
  logic[7:0] ctr_d;
  logic[7:0] ctr_q;

  // Combinational logic for the counter
  always_comb begin
    ctr_d = 8'h00;

    if (reset) begin
      ctr_d = 8'h01;
    end else begin
      ctr_d = ctr_q + 8'h02;
    end
  end

  // Counter Register logic
  always_ff @(posedge clk) begin
    ctr_q <= ctr_d;
  end

  // Output logic
  assign cnt_o = ctr_q;

endmodule

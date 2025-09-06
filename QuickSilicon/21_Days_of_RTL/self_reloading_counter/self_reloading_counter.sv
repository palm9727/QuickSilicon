// Counter with a load

module self_reloading_counter (
  input     wire          clk,
  input     wire          reset,
  input     wire          load_i,
  input     wire[3:0]     load_val_i,

  output    wire[3:0]     count_o
);

  // Counter signals
  logic[3:0] sr_ctr;
  logic[3:0] sr_ctr_q;

  // Counter logic
  always_comb begin
    sr_ctr = 4'h0; //? Avoiding latch

    if (reset) begin
      sr_ctr = 4'h0;
    end else begin
      if (sr_ctr_q == 4'hf) begin
        if (load_i) begin
          sr_ctr = load_val_i;
        end else begin
          sr_ctr = 4'h0;
        end
      end else begin
        sr_ctr = sr_ctr_q + 4'h1;
      end
    end
  end

  // Counter register
  always_ff @(posedge clk) begin
    sr_ctr_q <= sr_ctr;
  end

  // Synchronous outuput logic
  assign count_o = sr_ctr_q;

endmodule

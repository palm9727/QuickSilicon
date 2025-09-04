// Binary to one-hot converter

module binary_to_one_hot #(
  parameter BIN_W       = 4,
  parameter ONE_HOT_W   = 16
)(
  input   wire[BIN_W-1:0]     bin_i,
  output  wire[ONE_HOT_W-1:0] one_hot_o
);

  // One Hot Signal
  logic[ONE_HOT_W-1:0] one_hot;

  // One Hot Logic
  always_comb begin
    one_hot = 0;

    for (int i = 0; i < ONE_HOT_W; i++) begin
      one_hot[i] = (bin_i == i);
    end
  end

  // Output logic
  assign one_hot_o = one_hot;

endmodule

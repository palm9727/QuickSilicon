// Binary to gray code

module binary_to_gray #(
  parameter VEC_W = 4
)(
  input     wire[VEC_W-1:0] bin_i,
  output    wire[VEC_W-1:0] gray_o

);

  // Gray Code signal
  logic[VEC_W-1:0] gray_code;

  // Gray Code logic
  always_comb begin
    gray_code = 0;

    for (int i = (VEC_W - 1); i >= 0; i--) begin
      if (i == (VEC_W - 1)) begin
        gray_code[i] = bin_i[i];
      end else begin
        gray_code[i] = bin_i[i + 1] ^ bin_i[i];
      end
    end
  end

  // Output logic
  assign gray_o = gray_code;

endmodule

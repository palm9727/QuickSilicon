// Find second bit set from LSB for a N-bit vector

module lsb_second_bit_set_finder #(
  parameter WIDTH = 12
)(
  input       wire [WIDTH-1:0]  vec_i,
  output      wire [WIDTH-1:0]  second_bit_o // One-Hot Output
);

  // Masks signals
  logic[WIDTH-1:0] first_mask;
  logic[WIDTH-1:0] im_second_mask; // Intermediate second mask
  logic[WIDTH-1:0] second_mask;

  // First Mask logic
  always_comb begin
    first_mask[0] = 0;
    for (int i = 1; i < WIDTH; i++) begin
      first_mask[i] = vec_i[i-1] | first_mask[i-1];
    end
  end

  // Intermediate Vector Logic
  logic[WIDTH-1:0] im_vec;

  assign im_vec = vec_i & first_mask;

  // Intermediate Second Mask Logic
  always_comb begin
    im_second_mask[0] = im_vec[0];
    for (int i = 1; i < WIDTH; i++) begin
      im_second_mask[i] = im_vec[i-1] | im_second_mask[i-1];
    end
  end

  // Second Mask Logic
  assign second_mask = ~im_second_mask;

  // Output Logic
  assign second_bit_o = im_vec & second_mask;

endmodule

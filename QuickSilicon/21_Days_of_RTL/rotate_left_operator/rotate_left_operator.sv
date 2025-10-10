// The ROL (Rotate Left) instruction shifts the bits of a register to the left, 
// with the bits that overflow from the most significant position reentering
// at the least significant position.

module rotate_left_operator #(
    parameter SIZE = 16, // Width of the data input and output
    parameter SHAMT_SIZE = $clog2(SIZE) // Width of the shift amount input
)(
    // Do not modify the input/output ports of this module
    input  wire [SIZE-1:0]       data_i                 , // Input data to be rotated
    input  wire [SHAMT_SIZE-1:0] shamt_i                , // Shift amount (number of positions to rotate)
    output wire [SIZE-1:0]       result_by_shift_o      , // Output result computed using the shift approach
    output wire [SIZE-1:0]       result_by_borders_o      // Output result computed using the border extension approach
);
    // In this task, you will need additional signals.
    logic[SIZE-1:0] result_by_borders;

    logic[SIZE-1:0] result_by_shift;
    logic[SIZE-1:0] first_im;
    logic[SIZE-1:0] second_im;

    // approach 1
    assign first_im = data_i << shamt_i;
    assign second_im = data_i >> (SIZE - shamt_i);
    assign result_by_shift = first_im | second_im;

    assign result_by_shift_o = result_by_shift;

    // approach 2
    always_comb begin
      for (int i = 0; i < SIZE; i++) begin
        if (shamt_i <= i) begin
          result_by_borders[i] = data_i[i-shamt_i];
        end else begin // shamt_i > i
          result_by_borders[i] = data_i[SIZE+i-shamt_i];
        end
      end
    end

    assign result_by_borders_o = result_by_borders;

endmodule

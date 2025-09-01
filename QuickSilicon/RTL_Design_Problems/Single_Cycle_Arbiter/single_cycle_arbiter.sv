// System used to implement a parameterized fixed priority arbiter giving priority to the LSBs.

module single_cycle_arbiter #(
  parameter N = 32
) (
  input   logic          clk,
  input   logic          reset,
  input   logic [N-1:0]  req_i,
  output  logic [N-1:0]  gnt_o
);

  // Logic used for the mask
  logic [N-1:0] mask;

  always_comb begin
    mask[0] = 1'b0;
    for (int i = 0; i < N-1; i++) begin
      mask[i+1] = mask[i] | req_i[i];
    end
  end

  // Logic used for the output
  assign gnt_o = req_i & ~mask;

endmodule


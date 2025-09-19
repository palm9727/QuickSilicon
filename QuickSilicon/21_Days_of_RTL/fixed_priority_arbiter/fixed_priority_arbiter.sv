// Priority arbiter
// port[0] - highest priority

module fixed_priority_arbiter #(
  parameter NUM_PORTS = 4
)(
    input       wire[NUM_PORTS-1:0] req_i,
    output      wire[NUM_PORTS-1:0] gnt_o   // One-hot grant signal
);

  // Logic for the intermediate mask
  logic[NUM_PORTS-1:0] intermediate_mask;

  always_comb begin
    intermediate_mask[0] = 1'b0;

    for (int i = 1; i < NUM_PORTS; i++) begin
      intermediate_mask[i] = req_i[i - 1] | intermediate_mask[i - 1];
    end
  end

  // Logic for the mask
  logic[NUM_PORTS-1:0] mask;

  assign mask = ~intermediate_mask;

  // Logic for grant output
  assign gnt_o = req_i & mask;

endmodule

module edge_capture (
  input   logic        clk,
  input   logic        reset,

  input   logic [31:0] data_i,

  output  logic [31:0] edge_o

);

  // data register logic
  logic [31:0] data_q;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      data_q <= 32'h00000000;
    else
      data_q <= data_i;

  // edge register logic
  logic [31:0] neg_edge_detected;
  logic [31:0] neg_edge_q;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      neg_edge_q <= 32'h00000000;
    end else begin
      for (int i = 0; i < 32; i++) begin
        if (neg_edge_detected[i]) begin
          if (~neg_edge_q[i])
            neg_edge_q[i] <= 1'b1;
        end
      end
    end
  end

  for (genvar i = 0; i < 32; i++) begin
    assign neg_edge_detected[i] = (data_q[i]) ? ((data_i[i]) ? 1'b0: 1'b1) : 1'b0;
  end

  for (genvar i = 0; i < 32; i++) begin
    assign edge_o[i] = neg_edge_detected[i] ? 1'b1 : neg_edge_q[i];
  end

endmodule

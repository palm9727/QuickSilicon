module clk_gen (
  input   logic        clk_in,

  input   logic        reset,

  output  logic        clk_v1,
  output  logic        clk_v2
);
  logic switch;

  always_ff @(posedge clk_in or negedge clk_in or posedge reset) begin
    if (reset) begin
      switch <= 1'b1;
      clk_v1 <= 1'b0;
      clk_v2 <= 1'b0;
    end
    
    if (clk_in) begin
      switch <= switch + 1'b1;
      if (switch)
        clk_v2 <= 1'b1;
      else
        clk_v1 <= 1'b1;
    end else begin
      clk_v1 <= 1'b0;
      clk_v2 <= 1'b0;
    end
  end

endmodule

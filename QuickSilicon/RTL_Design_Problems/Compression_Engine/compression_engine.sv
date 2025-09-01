module compression_engine (
  input   logic        clk,
  input   logic        reset,

  input   logic [23:0] num_i,

  output  logic [11:0] mantissa_o,
  output  logic [3:0]  exponent_o
);

  logic [11:0] exp_oh;
  logic [3:0] exp_bin;

  logic [11:0] mantissa;
  logic [3:0] exponent;

  assign exp_oh[11] = num_i[11+12];

  for (genvar i = 10; i >= 0; i--) begin
    assign exp_oh[i] = num_i[i+12] & ~|exp_oh[11:i+1];
  end

  qs_1hot_bin #(.ONE_HOT_W(12), .BIN_W(4)) exp_oh_bin (
    .clk       (clk),
    .reset     (reset),
    .oh_vec_i  (exp_oh),
    .bin_vec_o (exp_bin)
  );

  assign exponent = (|exp_oh) ? exp_bin + 4'h1 : 4'h0;

  assign mantissa = (|exp_oh) ? num_i[exponent+10 -: 12] : 
                                num_i[11:0];

  assign mantissa_o = mantissa;
  assign exponent_o = exponent;

endmodule

module async_reset (
  input   logic        clk,
  input   logic        reset,

  output  logic        release_reset_o,
  output  logic        gate_clk_o

);

  logic [4:0] n_rst_cntr_q;
  logic [4:0] nxt_n_rst_cntr;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      n_rst_cntr_q <= 0;
    else
      n_rst_cntr_q <= nxt_n_rst_cntr;

  assign nxt_n_rst_cntr = reset ? 0 : 
                          (n_rst_cntr_q == 5'b10010) ? n_rst_cntr_q :
                          (n_rst_cntr_q + 1);

  assign gate_clk_o = (nxt_n_rst_cntr > 5'b00100) & (nxt_n_rst_cntr < 5'b10010);

  assign release_reset_o = (nxt_n_rst_cntr > 5'b01010);

endmodule

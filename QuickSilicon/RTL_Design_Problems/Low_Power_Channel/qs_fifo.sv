module qs_fifo #(
  parameter DATA_W = 4,
  parameter DEPTH  = 4
)(
  input   logic               clk,
  input   logic               reset,

  input   logic               push_i,
  input   logic [DATA_W-1:0]  push_data_i,

  input   logic               pop_i,
  output  logic [DATA_W-1:0]  pop_data_o,

  output  logic               empty_o,
  output  logic               full_o
);

endmodule
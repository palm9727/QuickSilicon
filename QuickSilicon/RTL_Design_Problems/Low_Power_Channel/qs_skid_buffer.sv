module qs_skid_buffer #(
  parameter DATA_W = 8
)(
  input   logic               clk,
  input   logic               reset,

  input   logic               i_valid_i,
  input   logic [DATA_W-1:0]  i_data_i,
  output  logic               i_ready_o,

  input   logic               e_ready_i,
  output  logic               e_valid_o,
  output  logic [DATA_W-1:0]  e_data_o
);
endmodule
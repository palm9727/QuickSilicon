module big_endian_converter #(
  parameter DATA_W = 32
)(
  input   logic              clk,
  input   logic              reset,

  input   logic [DATA_W-1:0] le_data_i,

  output  logic [DATA_W-1:0] be_data_o

);
  integer i;
  parameter BITS_PER_BYTE = 8;
  parameter BYTES_N = DATA_W/8;
  parameter HIGH_I = (i*8)-1;
  parameter LOW_I = (i*8)-8;
  parameter BYTES_I = i-1;

  logic [BYTES_N-1:0] [7:0] le_bytes;

  always_comb begin
    for (i = BYTES_N; i > 0; i--) begin
      le_bytes[BYTES_I] = le_data_i[HIGH_I:LOW_I];
    end
  end

  logic [BYTES_N-1:0] [7:0] be_bytes;

  always_comb begin
    for (i = BYTES_N; i > 0; i--) begin
      be_bytes[BYTES_I] = le_bytes[4-i];
    end
  end

  always_comb begin
    for (i = BYTES_N; i > 0; i--) begin
      be_data_o[HIGH_I:LOW_I] = be_bytes[BYTES_I];
    end
  end

endmodule

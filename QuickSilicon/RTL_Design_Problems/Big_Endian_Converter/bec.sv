module big_endian_converter #(
  parameter DATA_W = 32
)(
  input   logic              clk,
  input   logic              reset,

  input   logic [DATA_W-1:0] le_data_i,

  output  logic [DATA_W-1:0] be_data_o

);

  localparam BYTE_N = DATA_W/8;
  localparam BITS_PER_BYTE = 8;

  always_comb begin
    for (int i = 0; i < BYTE_N; i++) begin
      for (int j = 0; j < BITS_PER_BYTE; j++) begin
        be_data_o[(i*BITS_PER_BYTE)+j] = le_data_i[(((BYTE_N-1)-i)*BITS_PER_BYTE)+j];
      end 
    end
  end

endmodule

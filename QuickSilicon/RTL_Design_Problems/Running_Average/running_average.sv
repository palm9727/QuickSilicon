// System with register files 

module running_average #(
  parameter N = 4
)(
  input   logic        clk,
  input   logic        reset,

  input   logic [31:0] data_i,

  output  logic [31:0] average_o 

);

  localparam SHIFT_N = $clog2(N);

  logic [31:0] d_reg [N-1];

  always_ff @(posedge clk or posedge reset) begin
    for (int i = 0; i < N-1; i++) begin
      if (reset) begin
        d_reg[i] <= 0;
      end else begin
        if (i == 0) begin
          d_reg[i] <= data_i;
        end else begin
          d_reg[i] <= d_reg[i-1];
        end
      end
    end
  end

  logic [31:0] s_wire [N-2];

  always_comb begin
    for (int i = 0; i < N-2; i++) begin
      if (i == 0) begin
        s_wire[i] = d_reg[i] + d_reg[i+1];
      end else begin
        s_wire[i] = s_wire[i-1] + d_reg[i+1];
      end
    end
  end

  assign average_o = (s_wire[N-3] + data_i) >> SHIFT_N;

endmodule

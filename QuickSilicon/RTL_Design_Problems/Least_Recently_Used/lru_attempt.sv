module lru #(
  parameter NUM_WAYS = 4
)(
  input   logic                         clk,
  input   logic                         reset,

  input   logic                         ls_valid_i,
  input   logic [1:0]                   ls_op_i,
  input   logic [$clog2(NUM_WAYS)-1:0]  ls_way_i,

  output  logic                         lru_valid_o,
  output  logic [NUM_WAYS-1:0]          lru_way_o
);

  // lru_valid_o logic
  assign lru_valid_o = (ls_op_i == 2'b10) & ls_valid_i;

  // lru_way_o logic
  logic [NUM_WAYS-1:0] way_q;
  logic [NUM_WAYS-1:0] way;
  logic [NUM_WAYS-1:0] mask;
  logic [NUM_WAYS-1:0] one_hot_signal;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      way_q <= 0;
    else
      way_q <= way;

  always_comb begin
    mask = 1;
    way = way_q;
    if (ls_op_i == 2'b10) begin // Validating ways
      for (int i = 0; i < NUM_WAYS-1; i++) begin // Generating mask
        mask[i+1] = mask[i] & way_q[i];
      end
      way = way_q | mask; // Saving new way
    end else if (ls_op_i == 2'b11) begin // Invalidating ways
      for (int i = 0; i < NUM_WAYS; i++) begin
        if (i == 32'(ls_way_i)) begin
          way[i] = 1'b0;
        end else begin
          way[i] = way_q[i];
        end
      end
    end
  end

  logic [NUM_WAYS-1:0] all_valid_way_q;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      all_valid_way_q <= 1;
    else
      if (way_q == '1)
        if (all_valid_way_q[NUM_WAYS-1])
          all_valid_way_q <= 1;
        else
          all_valid_way_q <= all_valid_way_q << 1;

  assign one_hot_signal = (way_q == '1) ? all_valid_way_q : ~(way_q | ~mask);

  assign lru_way_o = lru_valid_o ? one_hot_signal : 0;

endmodule

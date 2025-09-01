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

  localparam WAYS_LOG2 = $clog2(NUM_WAYS);

  typedef enum logic [1:0] {
    LOAD       = 2'b01,
    STORE      = 2'b10,
    INVALIDATE = 2'b11
  } op_t;

  logic                ld_valid;
  logic [NUM_WAYS-1:0] ld_way;
  logic                st_valid;
  logic                inv_valid;
  logic [NUM_WAYS-1:0] inv_way;

  // LOAD valid and one-hot signal logic
  assign ld_valid = ls_valid_i & (ls_op_i == LOAD);
  for (genvar i = 0; i < NUM_WAYS; i++) begin : ld_one_hot_signal
    assign ld_way[i] = ld_valid & (ls_way_i == i[WAYS_LOG2-1:0]);
  end

  // STORE valid and one-hot signal logic
  assign st_valid = ls_valid_i & (ls_op_i == STORE);

  // INVALIDATE valid and one-hot signal logic
  assign inv_valid = ls_valid_i & (ls_op_i == INVALIDATE);
  for (genvar i = 0; i < NUM_WAYS; i++) begin : inv_one_hot_signal
    assign inv_way[i] = inv_valid & (ls_way_i == i[WAYS_LOG2-1:0]);
  end

  // Ways logic
  logic [NUM_WAYS-1:0] available_ways_q;
  logic [NUM_WAYS-1:0] nxt_available_ways;
  logic [NUM_WAYS-1:0] valid_ways;
  logic [NUM_WAYS-1:0] selected_way;

  logic [NUM_WAYS-1:0] [NUM_WAYS-1:0] lru_matrix;
  logic [NUM_WAYS-1:0] active_ways;

  logic [NUM_WAYS-1:0] oldest_way;

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      available_ways_q <= {NUM_WAYS{1'b1}};
    else
      available_ways_q <= nxt_available_ways;
  end

  assign nxt_available_ways = inv_way | (available_ways_q & ~selected_way);
  assign valid_ways = ~available_ways_q;

  // Oldest and Selected way logic
  assign oldest_way[0] = ~|(lru_matrix[0] & valid_ways);
  assign selected_way[0] = st_valid & (available_ways_q[0] | (~|available_ways_q & oldest_way[0]));

  for (genvar i = 1; i < NUM_WAYS; i++) begin
    assign oldest_way[i] = ~|(lru_matrix[i] & valid_ways);
    assign selected_way[i] = st_valid & ~|selected_way[i-1:0] & (available_ways_q[i] | (~|available_ways_q & oldest_way[i]));
  end

  // Least Recently Used Matrix logic
  assign active_ways = selected_way | ld_way;

  // When LRU all columns in the way's row are 0, and all rows in the way's column are 1 (except for the diagonal).
  for (genvar i = 0; i < NUM_WAYS; i++) begin
    for (genvar j = 0; j < NUM_WAYS; j++) begin
      if (i == j) begin
        assign lru_matrix[i][j] = 1'b0;
      end else if (i < j) begin
        assign lru_matrix[i][j] = ~lru_matrix[j][i];
      end else begin
        logic value_q;
        logic nxt_value;

        // If MRU set the row and clear the column
        assign nxt_value = (active_ways[i] | lru_matrix[i][j]) & ~active_ways[j];

        always_ff @(posedge clk)
          if (|active_ways)
            value_q <= nxt_value;

        assign lru_matrix[i][j] = value_q;
      end
    end
  end

  // Output logic
  assign lru_valid_o = st_valid;
  assign lru_way_o = selected_way;

endmodule

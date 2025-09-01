module ordering (
  input   logic        clk,
  input   logic        reset,

  // RX side interface
  input   logic        rx_valid_i,
  input   logic [2:0]  rx_id_i,
  input   logic [15:0] rx_payload_i,
  input   logic        rx_order_i,
  output  logic        rx_ready_o,

  // RX retire interface
  input   logic        rx_ret_i,
  input   logic [2:0]  rx_ret_id_i,

  // TX side interface
  output  logic        tx_valid_o,
  output  logic [2:0]  tx_id_o,
  output  logic [15:0] tx_payload_o,
  input   logic        tx_ready_i

);

  typedef struct packed {
    logic [2:0] id;
    logic [15:0] payload;
    logic retired;
    logic inorder;
  } table_t;

  table_t [7:0] entry_q;
  table_t [7:0] nxt_entry;

  table_t tx_data;

  logic [7:0] entry_avail_q;
  logic [7:0] nxt_entry_avail;

  logic [7:0] entry_valid;
  logic [7:0] entry_retired;

  logic [7:0] entry_sel;

  logic [7:0] entry_read;

  logic ordered_entry;

  for (genvar i = 0; i < 8; i++) begin
    logic entry_en;
    logic oldest;

    assign oldest = ~|(track_older[i] & entry_valid);
    assign entry_en = entry_sel[i] | entry_retired[i] | oldest;

    assign nxt_entry[i].id = entry_sel[i] ? rx_id_i : entry_q[i].id;
    assign nxt_entry[i].payload = entry_sel[i] ? rx_payload_i : entry_q[i].payload;
    assign nxt_entry[i].retired = (entry_retired[i] | entry_q[i].retired) & ~entry_sel[i];
    assign nxt_entry[i].inorder = (oldest | entry_q[i].inorder) & ~entry_sel[i];

    always_ff @(posedge clk) begin
      if (entry_en)
        entry_q[i] <= nxt_entry[i];
    end
  end

  always_ff @(posedge clk or posedge reset)
    if (reset)
      entry_avail_q <= 8'hff;
    else
      entry_avail_q <= nxt_entry_avail;

  assign nxt_entry_avail = (entry_avail_q & ~entry_sel) |
                           (entry_read & {8{tx_ready_i}});

  assign entry_valid = ~entry_avail_q;

  assign entry_sel[0] = rx_valid_i & entry_avail_q[0];

  for (genvar i = 1; i < 8; i++) begin
    assign entry_sel[i] = rx_valid_i & ~|entry_sel[i-1:0] & entry_avail_q[i];
  end

  for (genvar i = 0; i < 8; i++) begin
    assign entry_retired[i] = rx_ret_i & entry_valid[i] & (entry_q[i].id == rx_ret_id_i);
  end

  assign rx_ready_o = |entry_avail_q;

  logic [7:0] [7:0] track_older;
  logic track_older_en;

  assign track_older_en = |entry_sel;

  assign ordered_entry = rx_valid_i & rx_order_i;

  for (genvar i = 0; i < 8; i++) begin
    for (genvar j = 0; j < 8; j++) begin
      if (i == j) begin
        assign track_older[i][j] = 1'b0;
      end else begin
        logic old_entry_q;
        logic nxt_old_entry;

        assign nxt_old_entry = (entry_sel[i] & ordered_entry) | track_older[i][j] & ~entry_sel[j];

        always_ff @(posedge clk)
          if (track_older_en)
            old_entry_q <= nxt_old_entry;

        assign track_older[i][j] = old_entry_q;
      end
    end
  end

  assign entry_read[0] = entry_valid[0] & entry_q[0].retired & entry_q[0].inorder;

  for (genvar i = 1; i < 8; i++) begin
    assign entry_read[i] = entry_valid[i] & ~|entry_read[i-1:0] & entry_q[i].retired & entry_q[i].inorder;
  end

  always_comb begin
    case(entry_read)
      8'b00000001: tx_data = entry_q[0];
      8'b00000010: tx_data = entry_q[1];
      8'b00000100: tx_data = entry_q[2];
      8'b00001000: tx_data = entry_q[3];
      8'b00010000: tx_data = entry_q[4];
      8'b00100000: tx_data = entry_q[5];
      8'b01000000: tx_data = entry_q[6];
      8'b10000000: tx_data = entry_q[7];
      default: tx_data = '0;
    endcase
  end

  assign tx_valid_o = |entry_read;
  assign tx_id_o = tx_data.id;
  assign tx_payload_o = tx_data.payload;

endmodule

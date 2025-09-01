module credit_n_deadlock (
  input   logic        clk,
  input   logic        reset,

  // RX side interface
  input   logic        rx_valid_i,
  input   logic [2:0]  rx_id_i,
  input   logic [4:0]  rx_payload_i,
  input   logic        rx_credit_i,
  output  logic        rx_ready_o,
  output  logic        rx_retry_o,

  // TX side interface
  output  logic        tx_valid_o,
  output  logic [2:0]  tx_id_o,
  output  logic [4:0]  tx_payload_o,
  input   logic        tx_ready_i,

  // Credit interface
  output  logic        credit_gnt_o,
  output  logic [2:0]  credit_id_o

);

  // DATA FIFO signals
  logic df_push;
  logic df_pop;
  logic [2:0] df_pop_id;
  logic [4:0] df_pop_payload;
  logic df_full;
  logic df_empty;
  logic df_stalled;

  // RX signals
  logic rx_ready;
  logic rx_retry;
  logic rx_retried_request;

  // TX SKID BUFFER signals
  logic tx_valid;
  logic [2:0] tx_id;
  logic [4:0] tx_payload;
  logic tx_free;
  logic tx_ready;

  // DEADLOCK COUNTER signals
  logic [1:0] deadlock_cnt_q;
  logic [1:0] nxt_deadlock_cnt;
  logic deadlock_en;

  // CREDIT FIFO signals
  logic cf_pop;
  logic [2:0] cf_pop_id;
  logic cf_empty;
  logic cf_full;

  // RESERVATION COUNTER signals
  logic [2:0] rsv_cnt_q;
  logic [2:0] nxt_rsv_cnt;
  logic rsv_cnt_inc;
  logic rsv_cnt_dec;
  logic rsv_cnt_max;

  qs_fifo #(.DEPTH(4), .DATA_W(8)) data_fifo (
    .clk (clk),
    .reset (reset),

    .push_i (df_push),
    .push_data_i ({rx_id_i, rx_payload_i}),

    .pop_i (df_pop),
    .pop_data_o ({df_pop_id, df_pop_payload}),

    .full_o (df_full),
    .empty_o (df_empty)
  );

  assign rx_retried_request = rx_valid_i & rx_credit_i;
  assign df_push = (rx_valid_i & ~rsv_cnt_max) | rx_retried_request;
  assign df_pop = tx_free & ~df_empty;
  assign rx_ready = ~rsv_cnt_max | rx_retried_request;
  assign df_stalled = rx_valid_i & rsv_cnt_max;

  assign tx_valid = ~df_empty;
  assign tx_id = df_pop_id;
  assign tx_payload = df_pop_payload;
  assign tx_free = tx_ready;

  qs_skid_buffer #(.DATA_W(8)) tx_skid_buffer (
    .clk (clk),
    .reset (reset),

    .i_valid_i (tx_valid),
    .i_data_i ({tx_id, tx_payload}),
    .i_ready_o (tx_ready),

    .e_valid_o (tx_valid_o),
    .e_data_o ({tx_id_o, tx_payload_o}),
    .e_ready_i (tx_ready_i)
  );
  
  always_ff @(posedge clk or posedge reset)
    if (reset)
      deadlock_cnt_q <= 2'h0;
    else
      deadlock_cnt_q <= nxt_deadlock_cnt;

  assign nxt_deadlock_cnt = df_pop ? 2'h0 :
                            deadlock_en ? deadlock_cnt_q :
                            df_stalled ? deadlock_cnt_q + 2'h1 :
                            deadlock_cnt_q;

  assign deadlock_en = (deadlock_cnt_q == 2'h2);

  assign rx_retry = df_stalled & deadlock_en & ~rx_credit_i;

  qs_fifo #(.DEPTH(4), .DATA_W(3)) credit_fifo (
    .clk (clk),
    .reset (reset),

    .push_i (rx_retry),
    .push_data_i (rx_id_i),

    .pop_i (cf_pop),
    .pop_data_o (cf_pop_id),

    .full_o (cf_full),
    .empty_o (cf_empty)
  );

  assign cf_pop = df_pop & ~cf_empty;

  assign credit_gnt_o = cf_pop;
  assign credit_id_o = cf_pop_id;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      rsv_cnt_q <= 3'h0;
    else
      rsv_cnt_q <= nxt_rsv_cnt;

  assign nxt_rsv_cnt = (rsv_cnt_inc & rsv_cnt_dec) ? rsv_cnt_q :
                       (rsv_cnt_inc) ? rsv_cnt_q + 3'h1 :
                       (rsv_cnt_dec) ? rsv_cnt_q - 3'h1 :
                       rsv_cnt_q;

  assign rsv_cnt_inc = (df_push & ~rx_credit_i) | cf_pop;
  assign rsv_cnt_dec = df_pop;
  assign rsv_cnt_max = (rsv_cnt_q == 3'h4);

  assign rx_ready_o = rx_ready;
  assign rx_retry_o = rx_retry;

endmodule

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

  // ID Fifo instantiation
  logic id_push_i;
  logic [2:0] id_push_data_i;
  logic id_pop_i;
  logic [2:0] id_pop_data_o;
  logic id_empty_o;
  logic id_full_o;

  parameter ID_DATA_W = 3;
  parameter ID_DEPTH = 5;

  qs_fifo #(ID_DATA_W, ID_DEPTH) id_fifo (
    clk,
    reset,
    id_push_i,
    id_push_data_i,
    id_pop_i,
    id_pop_data_o,
    id_empty_o,
    id_full_o
  );

  // PAYLOAD Fifo instantiation
  logic pl_push_i;
  logic [2:0] pl_push_data_i;
  logic pl_pop_i;
  logic [2:0] pl_pop_data_o;
  logic pl_empty_o;
  logic pl_full_o;

  parameter PL_DATA_W = 5;
  parameter PL_DEPTH = 5;

  qs_fifo #(PL_DATA_W, PL_DEPTH) pl_fifo (
    clk,
    reset,
    pl_push_i,
    pl_push_data_i,
    pl_pop_i,
    pl_pop_data_o,
    pl_empty_o,
    pl_full_o
  );

  // CREDIT ID Fifo instantiation
  logic cid_push_i;
  logic [2:0] cid_push_data_i;
  logic cid_pop_i;
  logic [2:0] cid_pop_data_o;
  logic cid_empty_o;
  logic cid_full_o;

  parameter CID_DATA_W = 3;
  parameter CID_DEPTH = 5;

  qs_fifo #(CID_DATA_W, CID_DEPTH) id_fifo (
    clk,
    reset,
    cid_push_i,
    cid_push_data_i,
    cid_pop_i,
    cid_pop_data_o,
    cid_empty_o,
    cid_full_o
  );

  // ID and PAYLOAD output signals
  logic [2:0] nxt_id_o;
  logic [2:0] id_o_q;
  logic [4:0] nxt_payload_o;
  logic [4:0] payload_o_q;

  // RX register logic
  typedef enum logic [2:0] {READY, ACCUMULATE, REJECT, WAITING_READY, WAITING_EMPTY} rx_state_t;
  rx_state_t rx_cs;
  rx_state_t rx_ns;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      rx_cs <= READY;
    else
      rx_cs <= rx_ns;

  // RX SM logic
  always_comb begin
    case(rx_cs)
      READY:
        if (tx_valid_o & ~tx_ready_i)
          rx_ns = ACCUMULATE;
        else
          rx_ns = READY;
      ACCUMULATE:
        if ((id_full_o | pl_full_o) & ~tx_ready_i)
          rx_ns = REJECT;
        else
          rx_ns = ACCUMULATE;
      REJECT:
        if (~rx_valid_i)
          rx_ns = WAITING_READY;
        else
          rx_ns = REJECT;
      WAITING_READY:
        if (tx_ready_i)
          rx_ns = WAITING_EMPTY;
        else
          rx_ns = WAITING_READY;
      WAITING_EMPTY:
        if (id_empty_o | pl_empty_o)
          rx_ns = READY;
        else
          rx_ns = WAITING_EMPTY;
      default:
        rx_ns = READY;
    endcase
  end

  // rx_ready_o logic
  always_comb begin
    rx_ready_o = 1'b1;

    if (rx_cs = READY)
      rx_ready_o = 1'b1;
    else if (rx_cs = ACCUMULATE)
      if (id_full_o | pl_full_o)
        rx_ready_o = 1'b0;
      else
        rx_ready_o = 1'b1;
    else if (rx_cs = REJECT)
      rx_ready_o = 1'b0;
    else if (rx_cs = WAITING_READY)
      rx_ready_o = 1'b0;
    else if (rx_cs = WAITING_EMPTY)
      if (id_empty_o | pl_empty_o)
        rx_ready_o = 1'b1;
      else
        rx_ready_o = 1'b0;
  end

  // rx_retry_o logic
  logic nxt_retry;
  logic retry_q;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      retry_q <= 1'b0;
    else
      retry_q <= nxt_retry;

  always_comb begin
    nxt_retry = 1'b0;

    if (rx_cs == REJECT)
      if (~tx_ready_i)
        nxt_retry = 1'b1;
      else
        nxt_retry = 1'b0;
  end

  assign rx_retry_o = (rx_valid_i) ? retry_q : 1'b0;

  // TX register logic
  typedef enum logic [1:0] {IDLE, TRANSMITING} tx_state_t;
  tx_state_t tx_cs;
  tx_state_t tx_ns;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      tx_cs <= IDLE;
    else
      tx_cs <= tx_ns;

  // TX SM logic
  always_comb begin
    case (tx_cs)
      IDLE:
        if (rx_valid_i & rx_ready_o)
          tx_ns = TRANSMITING;
        else
          tx_ns = IDLE;
      TRANSMITING:
        if (id_empty_o | pl_empty_o)
          tx_ns = IDLE;
        else
          tx_ns = TRANSMITING;
      default:
        tx_ns = IDLE;
    endcase
  end

  // tx_valid_o logic
  always_comb begin
    tx_valid_o = 1'b0;

    if (tx_cs == TRANSMITING)
      tx_valid_o = 1'b1;
  end

  // tx_id_o and tx_payload_o logic
  always_comb begin
    tx_id_o = '0;
    tx_payload_o = '0;

    if (tx_cs == TRANSMITING) begin
      
    end
  end

endmodule

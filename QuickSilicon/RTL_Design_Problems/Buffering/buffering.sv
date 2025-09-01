module buffering (
  input   logic        clk,
  input   logic        reset,

  // Incoming AXI Stream interface
  input   logic        req_tvalid_i,
  input   logic [2:0]  req_tid_i,
  input   logic [15:0] req_tdata_i,
  output  logic        req_tready_o,

  // Outgoing valid-ready interface
  output  logic        dev_valid_o,
  output  logic [18:0] dev_addr_o,
  output  logic [15:0] dev_data_o,
  input   logic        dev_ready_i,

  // Device status interface
  input   logic        dev_opmode_i
);

  logic req_tready;

  logic buf2dev_transfer;
  logic [2:0] buf2dev_tid;
  logic [15:0] buf2dev_tdata;

  logic buf2req_tready;

  logic [18:0] nxt_addr;
  logic [18:0] addr_q;
  logic [15:0] nxt_data;
  logic [15:0] data_q;

  logic buf_push;
  logic buf_pop;
  logic [15:0] buf_pop_data;
  logic buf_full;
  logic buf_empty;

  logic buf_drain;
  logic buf_drain_q;

  // 16 deep Buffer inst
  qs_fifo #(.DEPTH(16), .DATA_W(16)) req_buf(
    .clk         (clk),
    .reset       (reset),

    .push_i      (buf_push),
    .push_data_i (req_tdata_i),

    .pop_i       (buf_pop),
    .pop_data_o  (buf_pop_data),

    .full_o      (buf_full),
    .empty_o     (buf_empty)
  ); 

  assign buf_push = req_tvalid_i & (req_tid_i == 3'h5) & ~dev_opmode_i;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      buf_drain_q <= 1'b0;
    else
      buf_drain_q <= buf_drain;

  assign buf_drain = ((cs == IDLE) & (~buf_empty) & dev_opmode_i) | (buf_drain_q & (~buf_empty));

  assign buf_pop = buf_drain & req_tready;

  assign buf2dev_tdata = buf_drain ? buf_pop_data : req_tdata_i;

  assign buf2dev_tid = buf_drain ? 3'h5 : req_tid_i;

  assign buf2dev_transfer = buf_pop | (req_tvalid_i & req_tready & ~buf_push);

  assign buf2req_tready = buf_push | (req_tready & ~buf_drain);

  typedef enum logic[1:0] {IDLE, DATA, TRANSFER} state_t;
  state_t cs;
  state_t ns;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      cs <= IDLE;
    else
      cs <= ns;

  always_ff @(posedge clk) begin
    addr_q <= nxt_addr;
    data_q <= nxt_data;
  end

  always_comb begin
    req_tready = 1'b0;

    case(cs)
      IDLE: begin
        req_tready = 1'b1;
        // 1st AXI stream beat
        if (buf2dev_transfer) begin
          ns = DATA;
          nxt_addr = {buf2dev_tdata, buf2dev_tid};
        end
      end
      DATA: begin
        req_tready = 1'b1;
        // 2nd AXI stream beat
        if (buf2dev_transfer) begin
          ns = TRANSFER;
          nxt_data = buf2dev_tdata;
        end
      end
      TRANSFER: begin
        if (dev_ready_i)
          ns = IDLE;
      end
      default: begin
        ns = IDLE;
      end
    endcase
  end

  assign dev_valid_o = (cs == TRANSFER);
  assign dev_addr_o = addr_q;
  assign dev_data_o = data_q;

  assign req_tready_o = buf2req_tready;

endmodule

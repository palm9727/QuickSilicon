module fifo_flush (
  input   logic         clk,
  input   logic         reset,

  input   logic         fifo_wr_valid_i,
  input   logic [3:0]   fifo_wr_data_i,

  output  logic         fifo_data_avail_o,
  input   logic         fifo_rd_valid_i,
  output  logic [31:0]  fifo_rd_data_o,

  input   logic         fifo_flush_i,
  output  logic         fifo_flush_done_o,

  output  logic         fifo_empty_o,
  output  logic         fifo_full_o
);

  logic [2:0] wr_row_ptr_q;
  logic [2:0] nxt_wr_row_ptr;

  logic [2:0] wr_col_ptr_q;
  logic [2:0] nxt_wr_col_ptr;

  logic [2:0] flush_row_ptr_q;
  logic [2:0] nxt_flush_row_ptr;

  logic [2:0] flush_col_ptr_q;
  logic [2:0] nxt_flush_col_ptr;

  logic flush_entire_row;
  logic nxt_fifo_flush;
  logic fifo_flush_q;
  logic flush_ptr_en;
  logic fifo_flush_done;

  logic [2:0] rd_row_ptr_q;
  logic [2:0] nxt_rd_row_ptr;

  logic [31:0] fifo_data_q [3:0];
  logic [3:0] nxt_fifo_data;
  logic [7:0] fifo_wr_en;

  logic fifo_empty;
  logic fifo_full;

  logic [2:0] fifo_data_cntr_q;
  logic [2:0] nxt_fifo_data_cntr;
  logic inc_cntr;
  logic dec_cntr;

  logic fifo_data_avail;

  logic [31:0] fifo_rd_data;

  // WRITE pointers logic
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      wr_row_ptr_q <= 3'h0;
      wr_col_ptr_q <= 3'h0;
    end else if (fifo_wr_valid_i | flush_entire_row) begin
      wr_row_ptr_q <= nxt_wr_row_ptr;
      wr_col_ptr_q <= nxt_wr_col_ptr;
    end
  end

  assign nxt_wr_row_ptr = (fifo_wr_valid_i & (&wr_col_ptr_q)) | flush_entire_row ? wr_row_ptr_q + 3'h1 :
                          wr_row_ptr_q;

  assign nxt_wr_col_ptr = flush_entire_row ? 3'h0 : wr_col_ptr_q + 3'h1;

  // READ pointers logic
  always_ff @(posedge clk or posedge reset)
    if (reset)
      rd_row_ptr_q <= 3'h0;
    else if (fifo_rd_valid_i)
      rd_row_ptr_q <= nxt_rd_row_ptr;

  assign nxt_rd_row_ptr = rd_row_ptr_q + 3'h1;

  // FLUSH pointers logic
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      flush_row_ptr_q <= 3'h0;
      flush_col_ptr_q <= 3'h0;
    end else if (flush_ptr_en) begin
      flush_row_ptr_q <= nxt_flush_row_ptr;
      flush_col_ptr_q <= nxt_flush_col_ptr;
    end
  end

  assign nxt_flush_row_ptr = flush_entire_row ? wr_row_ptr_q :
                                                wr_row_ptr_q - 3'h1;
      
  assign nxt_flush_col_ptr = (fifo_wr_valid_i & (~&wr_col_ptr_q)) ? wr_col_ptr_q + 3'h1:
                             (flush_entire_row)                   ? wr_col_ptr_q:
                                                                    3'h7;

  assign flush_ptr_en = fifo_flush_i & ~fifo_flush_q;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      fifo_flush_q <= 1'b0;
    else
      fifo_flush_q <= nxt_fifo_flush;
  
  assign nxt_fifo_flush = fifo_flush_i & ~fifo_flush_done;

  assign flush_entire_row = (|wr_col_ptr_q | fifo_wr_valid_i) & flush_ptr_en;

  // FIFO write data
  assign nxt_fifo_data = fifo_wr_data_i;

  for (genvar i = 0; i < 8; i++) begin
    assign fifo_wr_en[i] = fifo_wr_valid_i & (wr_col_ptr_q == i[2:0]);
  end

  for (genvar i = 0; i < 8; i++) begin
    always_ff @(posedge clk)
      if (fifo_wr_en[i])
        fifo_data_q[wr_row_ptr_q[1:0]][i*4+:4] <= nxt_fifo_data;
  end

  // FIFO empty and full flags
  assign fifo_empty = (rd_row_ptr_q[2:0] == wr_row_ptr_q[2:0]) & 
                      (~|wr_col_ptr_q[2:0]);

  assign fifo_full = (rd_row_ptr_q[1:0] == wr_row_ptr_q[1:0]) &
                     (rd_row_ptr_q[2] != wr_row_ptr_q[2])     &
                     (~|wr_col_ptr_q[2:0]);

  // FIFO data available and FIFO read
  always_ff @(posedge clk or posedge reset)
    if (reset)
      fifo_data_cntr_q <= 3'h0;
    else
      fifo_data_cntr_q <= nxt_fifo_data_cntr;

  assign inc_cntr = (&wr_col_ptr_q) & fifo_wr_valid_i;
  assign dec_cntr = (|fifo_data_cntr_q) & fifo_rd_valid_i;

  assign nxt_fifo_data_cntr = (inc_cntr & dec_cntr) ? fifo_data_cntr_q:
                              (inc_cntr)            ? fifo_data_cntr_q + 3'h1:
                              (dec_cntr)            ? fifo_data_cntr_q - 3'h1:
                                                      fifo_data_cntr_q;

  assign fifo_data_avail = (|fifo_data_cntr_q) | 
                           (fifo_flush_q & (~fifo_empty | ~fifo_flush_done));

  assign fifo_flush_done = (fifo_flush_q & fifo_rd_valid_i) &
                           (rd_row_ptr_q[2:0] == flush_row_ptr_q[2:0]);

  for (genvar i = 0; i < 8; i++) begin
    assign fifo_rd_data[i*4+:4] = fifo_flush_q ? 
                                  ((rd_row_ptr_q[2:0] == flush_row_ptr_q[2:0]) & (flush_col_ptr_q[2:0] <= i[2:0]) & ~(&flush_col_ptr_q)) ?
                                  4'hC :
                                  fifo_data_q[rd_row_ptr_q[1:0]][i*4+:4]:
                                  fifo_data_q[rd_row_ptr_q[1:0]][i*4+:4];
  end

  assign fifo_data_avail_o = fifo_data_avail;
  assign fifo_rd_data_o = fifo_rd_data;
  assign fifo_empty_o = fifo_empty;
  assign fifo_full_o = fifo_full;
  assign fifo_flush_done_o = fifo_flush_done;

endmodule

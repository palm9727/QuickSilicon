// Parameterized fifo

module fifo #(
  parameter DEPTH   = 4,
  parameter DATA_W  = 1
)(
  input         wire              clk,
  input         wire              reset,

  input         wire              push_i,
  input         wire[DATA_W-1:0]  push_data_i,

  input         wire              pop_i,
  output        wire[DATA_W-1:0]  pop_data_o,

  output        wire              full_o,
  output        wire              empty_o
);

  // FIFO Push and Pop Logic
  logic [DEPTH-1:0] [DATA_W-1:0] mem;
  logic [DATA_W-1:0] pop_data;

  always_ff @(posedge clk) begin
    if (reset) begin
      pop_data <= 0;
      for (int i = 0; i < DEPTH; i++) begin
        mem[i] <= 0;
      end
    end else begin
      if (push_i & ~pop_i) begin
        mem[0] <= push_data_i;
        for (int i = 1; i < DEPTH; i++) begin
          mem[i] <= mem[i-1];
        end
        pop_data <= 0;
      end else if (pop_i & ~push_i) begin
        mem[0] <= 0;
        for (int i = 1; i < DEPTH; i++) begin
          mem[i] <= mem[i-1];
        end
        pop_data <= mem[DEPTH-1];
      end else if (push_i & pop_i) begin
        mem[0] <= push_data_i;
        for (int i = 1; i < DEPTH; i++) begin
          mem[i] <= mem[i-1];
        end
        pop_data <= mem[DEPTH-1];
      end
    end
  end

  assign pop_data_o = pop_data;

  // FIFO Full and Empty Logic
  logic [DEPTH-1:0] mem_used;
  logic [DEPTH-1:0] mem_used_q;

  always_ff @(posedge clk) begin
    mem_used_q <= mem_used;
  end

  always_comb begin
    mem_used = 0;

    if (reset) begin
      mem_used = 0;
    end else begin
      if (push_i) begin
        mem_used[0] = 1;
        for (int i = 1; i < DEPTH; i++) begin
          mem_used[i] = mem_used_q[i-1];
        end
      end else if (pop_i) begin
        mem_used[0] = 0;
        for (int i = 1; i < DEPTH; i++) begin
          mem_used[i] = mem_used_q[i-1];
        end
      end else begin
        mem_used = mem_used_q;
      end
    end
  end

  assign full_o = (mem_used_q == '1) ? 1'b1 : 1'b0;
  assign empty_o = (mem_used_q == 0) ? 1'b1 : 1'b0;

endmodule

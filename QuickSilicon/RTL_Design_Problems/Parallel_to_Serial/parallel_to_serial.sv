module parallel_to_serial #(
  parameter DATA_W = 4
)(
  input   logic               clk,
  input   logic               reset,

  input   logic               p_valid_i,
  input   logic [DATA_W-1:0]  p_data_i,
  output  logic               p_ready_o,

  output  logic               s_valid_o,
  output  logic               s_data_o,
  input   logic               s_ready_i
);

  localparam DATA_N = $clog2(DATA_W);

  // SM register logic
  typedef enum logic[1:0] {IDLE, SERIAL, DELAY, DONE} state_t;
  state_t cs;
  state_t ns;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      cs <= IDLE;
    else
      cs <= ns;

  // index ctr logic
  logic [DATA_N-1:0] index_ctr;
  logic clear_ctr;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      index_ctr <= 0;
    else
      if ((cs == SERIAL) & s_ready_i)
        index_ctr <= index_ctr + 1;
      else if (clear_ctr)
        index_ctr <= 0;

  // Shift register logic
  logic [DATA_W-1:0] data_q;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      data_q <= 0;
    else if (p_valid_i & p_ready_o)
      data_q <= p_data_i;
    else if (~p_ready_o & s_ready_i)
      data_q <= data_q >> 1;

  // SM state logic
  always_comb begin
    clear_ctr = 1'b0;
    case(cs)
      IDLE:
        if (p_valid_i)
          ns = SERIAL;
        else
          ns = IDLE;
      SERIAL:
        if (index_ctr == '1)
          if (~s_ready_i) begin
            ns = SERIAL;
          end else if (s_ready_i & p_valid_i) begin
            ns = DELAY;
            clear_ctr = 1'b1;
          end else begin
            ns = DONE;
          end
        else
          ns = SERIAL;
      DELAY:
        ns = SERIAL;
      DONE:
        ns = DONE;
      default:
        ns = IDLE;
    endcase
  end

  // p_ready_o logic
  assign p_ready_o = (cs != SERIAL); 

  // s_valid_o logic
  assign s_valid_o = ~p_ready_o;

  // s_data_o logic
  always_comb begin
    s_data_o = 1'b0;
    if (cs == IDLE) begin
      s_data_o = 1'b0;
    end else begin
      s_data_o = data_q[0];
    end
  end

endmodule

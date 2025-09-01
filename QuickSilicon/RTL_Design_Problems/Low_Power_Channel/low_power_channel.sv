module low_power_channel (
  input   logic          clk,
  input   logic          reset,

  // Wakeup interface
  input   logic          if_wakeup_i,

  // Write interface
  input   logic          wr_valid_i,
  input   logic [7:0]    wr_payload_i,

  // Upstream flush interface
  output  logic          wr_flush_o,
  input   logic          wr_done_i,

  // Read interface
  input   logic          rd_valid_i,
  output  logic [7:0]    rd_payload_o,

  // Q-channel interface
  input   logic          qreqn_i,
  output  logic          qacceptn_o,
  output  logic          qactive_o

);
  // Q-Channel state logic
  typedef enum logic [1:0] {RUN, REQUEST, STOPPED, EXIT} state_t;
  state_t cs;
  state_t ns;

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      cs <= RUN;
    else
      cs <= ns;
  end

  // Fifo instantiation
  logic push_i;
  logic [7:0] push_data_i;
  logic pop_i;
  logic [7:0] pop_data_o;
  logic empty_o;
  logic full_o;

  parameter DATA_W = 8;
  parameter DEPTH = 6;

  qs_fifo #(DATA_W, DEPTH) fifo (
    clk,
    reset,
    push_i,
    push_data_i,
    pop_i,
    pop_data_o,
    empty_o,
    full_o
  );

  // Write interface logic
  assign push_i = wr_valid_i;
  assign push_data_i = wr_payload_i;

  // Read interface logic
  assign pop_i = rd_valid_i;
  assign rd_payload_o = pop_data_o;

  // wr_flush_o logic
  always_ff @(posedge clk or posedge reset)
    if (reset)
      wr_flush_o <= 1'b0;
    else
      wr_flush_o <= ((cs == REQUEST) | wr_flush_o) & ~wr_done_i;

  // qacceptn_o logic
  logic acceptn;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      acceptn <= 1'b1;
    else
      if (cs == REQUEST || cs == EXIT)        
        acceptn <= ~(empty_o & wr_done_i & ~qreqn_i);  // TODO: Might need to take away qreqn_i from this logic
        
  assign qacceptn_o = acceptn;

  // qactive_o logic
  logic active;
  logic active_q;

  assign active = wr_valid_i | rd_valid_i | (~empty_o & ~full_o); //? Added the & ~full_o to pass the linter lol 

  always_ff @(posedge clk or posedge reset)
    if (reset)
      active_q <= 1'b0;
    else
      active_q <= active;

  assign qactive_o = active_q | if_wakeup_i;

  // Q-Channel FSM logic
  always_comb begin
    case(cs)
      RUN: begin
        if (~qreqn_i)
          ns = REQUEST;
        else
          ns = RUN;
      end
      REQUEST: begin
        if (~qacceptn_o)
          ns = STOPPED;
        else
          ns = REQUEST;
      end
      STOPPED: begin
        if (qreqn_i)
          ns = EXIT;
        else
          ns = STOPPED;
      end
      EXIT: begin
        if (qacceptn_o)
          ns = RUN;
        else
          ns = EXIT;
      end
      default:
        ns = RUN;
    endcase
  end

endmodule

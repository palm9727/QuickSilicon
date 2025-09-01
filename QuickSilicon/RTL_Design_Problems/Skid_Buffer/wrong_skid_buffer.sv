// First attempt of the skid_buffer based on the waveform example

module skid_buffer (
  input   logic        clk,
  input   logic        reset,

  input   logic        i_valid_i,
  input   logic [7:0]  i_data_i,
  output  logic        i_ready_o,

  input   logic        e_ready_i,
  output  logic        e_valid_o,
  output  logic [7:0]  e_data_o
);

  // Ready SM register logic
  typedef enum logic [1:0] {START, IDLE, READY, ERR='X} state_t;
  state_t cs;
  state_t ns;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      cs <= START;
    else
      cs <= ns;

  // e_valid_o logic
  assign e_valid_o = i_valid_i;

  // e_data_o logic
  logic [7:0] data_q;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      data_q <= 8'h00;
    else
      data_q <= e_data_o;

  always_comb
    if (e_valid_o)
      if (i_ready_o)
        e_data_o = i_data_i;
      else
        e_data_o = data_q;
    else
      e_data_o = 8'h00;

  // i_ready_o logic
  always_comb begin
    i_ready_o = 1'b0;

    if (cs == START && i_valid_i)
      i_ready_o = 1'b1;
    else if (cs == READY && e_ready_i)
      i_ready_o = 1'b1;
  end

  // Ready SM transitions logic
  always_comb begin
    case(cs)
      START: begin
        if (i_valid_i)
          ns = READY;
        else
          ns = START;
      end
      IDLE: begin
        if (e_ready_i)
          ns = READY;
        else
          ns = IDLE;
      end
      READY: begin
        if (i_valid_i)
          if (e_ready_i)
            ns = READY;
          else
            ns = IDLE;
        else
          ns = START;
      end
      default:
        ns = ERR;
    endcase
  end

endmodule

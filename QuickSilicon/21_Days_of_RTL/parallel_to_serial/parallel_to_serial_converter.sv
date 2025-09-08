// Parallel to serial with valid and empty

module parallel_to_serial_converter (
  input     wire      clk,
  input     wire      reset,

  output    wire      empty_o,
  input     wire[3:0] parallel_i,
  
  output    wire      serial_o,
  output    wire      valid_o
);

  // Valid, Empty signals
  logic valid;
  logic empty;

  // Parallel Input register logic
  logic[3:0] parallel_q;

  always_ff @(posedge clk) begin
    parallel_q <= parallel_i;
  end

  // Serial counter logic
  logic[1:0] s_ctr;
  logic[1:0] s_ctr_q;

  always_comb begin
    s_ctr = 0;
    if (valid) begin
      if (s_ctr_q == 2'b11) begin
        s_ctr = 0;
      end else begin
        s_ctr = s_ctr_q + 2'b01;
      end
    end
  end

  always_ff @(posedge clk) begin
    s_ctr_q <= s_ctr;
  end

  // SM signals
  typedef enum logic[1:0] {IDLE, SERIAL, DONE} state_t;
  state_t cs;
  state_t ns;

  // State register
  always_ff @(posedge clk) begin
    cs <= ns;
  end

  // SM Logic
  always_comb begin
    ns = IDLE; //? Avoiding latch
    valid = 1'b0;
    empty = 1'b0;

    if (reset) begin
      ns = IDLE;
    end else begin
      case(cs)
        IDLE: begin
          if (parallel_q != parallel_i) begin
            ns = SERIAL;
          end else begin
            ns = IDLE;
          end
        end
        SERIAL: begin
          valid = 1'b1;
          if (s_ctr_q == 2'b11) begin
            ns = DONE;
          end else begin
            ns = SERIAL;
          end
        end
        DONE: begin
          empty = 1'b1;
          if (parallel_q != parallel_i) begin
            ns = SERIAL;
          end else begin
            ns = IDLE;
          end
        end
        default: begin
          ns = IDLE;
        end
      endcase
    end
  end

  // Valid Output Logic
  assign valid_o = valid;

  // Empty Output Logic
  assign empty_o = empty;

  // Serial Output Logic
  assign serial_o = valid_o ? parallel_i[s_ctr_q] : 1'b0;

endmodule

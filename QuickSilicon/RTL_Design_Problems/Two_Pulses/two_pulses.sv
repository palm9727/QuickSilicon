module two_pulses (
  input   logic       clk,
  input   logic       reset,

  input   logic       x_i,
  input   logic       y_i,

  output  logic       p_o

);

  // SM register logic
  typedef enum logic [1:0] {IDLE, READY, SET, ERR='X} state_t;
  state_t cs;
  state_t ns;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      cs <= IDLE;
    else
      cs <= ns;

  // y_ctr logic
  logic [7:0] y_ctr;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      y_ctr <= 8'h00;
    end else begin
      if (x_i & y_i) begin
        y_ctr <= 8'h01;
      end else if (x_i & ~y_i) begin
        y_ctr <= 8'h00;
      end else if (y_i) begin
        y_ctr <= y_ctr + 8'h01;
      end
    end
  end

  // SM states and output logic
  always_comb begin
    p_o = 1'b0;
    ns = ERR;

    case(cs)
      IDLE: begin
        if (x_i)
          ns = READY;
        else
          ns = IDLE;
      end
      READY: begin
        if (x_i && (y_ctr == 8'h02)) begin
          ns = SET;
          p_o = 1'b1;
        end else begin
          ns = READY;
        end
      end
      SET: begin
        p_o = 1'b1;
        if (y_i) begin
          ns = READY;
          p_o = 1'b0;
        end else begin
          ns = SET;
        end
      end
      default:
        ns = ERR;
    endcase
  end

endmodule

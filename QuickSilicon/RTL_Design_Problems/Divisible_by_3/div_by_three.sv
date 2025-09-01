// System used to recognize if a serial number is divisible by 3
// given the value of the input and the remainder of the current number
// represented by a state.

// Remainders: 0, 1, 2
// REM_0: a%3=0
// x_i=0 => {a,0} => 2a%3=0
// x_i=1 => {a,1} => (2a+1)%3=1
// REM_1:  (2a+1)%3=1
// x_i=0 => {2a+1,0} => (4a+2)%3=2
// x_i=1 => {2a+1,1} => (4a+3)%3=0
// REM_2: (4a+2)%3=2
// x_i=0 => {4a+2,0} => (8a+4)%3=1
// x_i=1 => {4a+2,1} => (8a+5)%3=2

module div_by_three (
  input   logic    clk,
  input   logic    reset,

  input   logic    x_i,

  output  logic    div_o

);

  // Logic for the state register
  typedef enum logic[1:0] {REM_0, REM_1, REM_2, ERR='X} state_t;
  state_t ns, cs;

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      cs <= REM_0;
    else
      cs <= ns;
  end

  // Logic for the output and the next state
  always_comb begin
    ns = ERR;
    div_o = 1'b0;

    if (reset) begin
      ns = REM_0;
    end else begin
      case(cs)
        REM_0: begin
          if (x_i) begin
            ns = REM_1;
          end else begin
            ns = REM_0;
            div_o = 1'b1;
          end
        end
        REM_1: begin
          if (x_i) begin
            ns = REM_0;
            div_o = 1'b1;
          end else begin
            ns = REM_2;
          end
        end
        REM_2: begin
          if (x_i) begin
            ns = REM_2;
          end else begin
            ns = REM_1;
          end
        end
        default: begin
          ns = REM_0;
        end
      endcase
    end
  end

endmodule
// Round robin arbiter

module round_robin_arbiter (
  input     wire        clk,
  input     wire        reset,

  input     wire[3:0]   req_i,
  output    logic[3:0]  gnt_o
);

  // Arbiter SM logic
  typedef enum logic[1:0] {FIRST, SECOND, THIRD, FOURTH} state_t;
  state_t cs;
  state_t ns;

  always_ff @(posedge clk) begin
    cs <= ns;
  end

  always_comb begin
    ns = FOURTH;
    gnt_o = 4'b0000;

    if (reset) begin
      ns = FOURTH;
    end else begin
      case(cs)
        FIRST: begin
          if (req_i[1]) begin
            ns = SECOND;
            gnt_o = 4'b0010;
          end else if (req_i[2]) begin
            ns = THIRD;
            gnt_o = 4'b0100;
          end else if (req_i[3]) begin
            ns = FOURTH;
            gnt_o = 4'b1000;
          end else if (req_i[0]) begin
            ns = FIRST;
            gnt_o = 4'b0001;
          end
        end
        SECOND: begin
          if (req_i[2]) begin
            ns = THIRD;
            gnt_o = 4'b0100;
          end else if (req_i[3]) begin
            ns = FOURTH;
            gnt_o = 4'b1000;
          end else if (req_i[0]) begin
            ns = FIRST;
            gnt_o = 4'b0001;
          end else if (req_i[1]) begin
            ns = SECOND;
            gnt_o = 4'b0010;
          end
        end
        THIRD: begin
          if (req_i[3]) begin
            ns = FOURTH;
            gnt_o = 4'b1000;
          end else if (req_i[0]) begin
            ns = FIRST;
            gnt_o = 4'b0001;
          end else if (req_i[1]) begin
            ns = SECOND;
            gnt_o = 4'b0010;
          end else if (req_i[2]) begin
            ns = THIRD;
            gnt_o = 4'b0100;
          end
        end
        FOURTH: begin
          if (req_i[0]) begin
            ns = FIRST;
            gnt_o = 4'b0001;
          end else if (req_i[1]) begin
            ns = SECOND;
            gnt_o = 4'b0010;
          end else if (req_i[2]) begin
            ns = THIRD;
            gnt_o = 4'b0100;
          end else if (req_i[3]) begin
            ns = FOURTH;
            gnt_o = 4'b1000;
          end
        end
        default: ns = FOURTH;
      endcase
    end
  end

endmodule

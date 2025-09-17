// Various ways to implement a mux

module muxes (
  input     wire[3:0] a_i,
  input     wire[3:0] sel_i,

  // Output using ternary operator
  output    wire     y_ter_o,
  // Output using case
  output    logic     y_case_o,
  // Ouput using if-else
  output    logic     y_ifelse_o,
  // Output using for loop
  output    logic     y_loop_o,
  // Output using and-or tree
  output    logic     y_aor_o
);
  // Ternary operator output logic
  assign y_ter_o = (sel_i == 4'b0001) ? a_i[0] : 
                   ((sel_i == 4'b0010) ? a_i[1] : 
                   ((sel_i == 4'b0100) ? a_i[2] : 
                   ((sel_i == 4'b1000) ? a_i[3] : 1'b0)));

  // Case output logic
  always_comb begin
    case(sel_i)
      4'b0001: y_case_o = a_i[0];
      4'b0010: y_case_o = a_i[1];
      4'b0100: y_case_o = a_i[2];
      4'b1000: y_case_o = a_i[3];
      default: y_case_o = 1'b0;
    endcase
  end

  // if-else output logic
  always_comb begin
    y_ifelse_o = 1'b0;

    if (sel_i == 4'b0001) begin
      y_ifelse_o = a_i[0];
    end else if (sel_i == 4'b0010) begin
      y_ifelse_o = a_i[1];
    end else if (sel_i == 4'b0100) begin
      y_ifelse_o = a_i[2];
    end else if (sel_i == 4'b1000) begin
      y_ifelse_o = a_i[3];
    end 
  end

  // for loop output logic
  always_comb begin
    y_loop_o = 1'b0;

    for (int i = 0; i < 4; i++) begin
      if (sel_i[i]) begin
        y_loop_o = a_i[i];
      end
    end
  end

  // and-or tree output logic
  assign y_aor_o = |(a_i & sel_i);

endmodule

// A simple ALU

module alu (
  input     logic [7:0]   a_i,
  input     logic [7:0]   b_i,
  input     logic [2:0]   op_i,

  output    logic [7:0]   alu_o
);

  // Logic for the ALU output
  always_comb begin : ALU
    alu_o = 8'h00;

    if (op_i == 3'b000) begin : ADD
      alu_o = a_i + b_i;
    end else if (op_i == 3'b001) begin : SUB
      alu_o = a_i - b_i;
    end else if (op_i == 3'b010) begin : SLL
      alu_o = a_i << b_i[2:0];
    end else if (op_i == 3'b011) begin : LSR
      alu_o = a_i >> b_i[2:0];
    end else if (op_i == 3'b100) begin : AND
      alu_o = a_i & b_i;
    end else if (op_i == 3'b101) begin : OR
      alu_o = a_i | b_i;
    end else if (op_i == 3'b110) begin : XOR
      alu_o = a_i ^ b_i;
    end else if (op_i == 3'b111) begin : EQL
      alu_o = {7'b0000000, (a_i == b_i)};
    end
  end

endmodule

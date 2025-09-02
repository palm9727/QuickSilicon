// A simple TB for the ALU

module alu_tb ();
    logic[7:0] a;
    logic[7:0] b;
    logic[2:0] op;
    logic[7:0] alu_o;

    // DUT instance
    alu ALU (
        .a_i   (a),
        .b_i   (b),
        .op_i (op),
        .alu_o   (alu_o)
    );

    // Testing the combinational logic of the ALU
    initial begin
        a = 8'b00000001;
        b = 8'b00000010;
        #5;

        op = 3'b000;
        #5;
        assert(alu_o == (a + b))
        else $sformatf("*** ERROR: expecting addition");
        #5;

        op = 3'b001;
        #5;
        assert(alu_o == (a - b))
        else $sformatf("*** ERROR: expecting subtraction");
        #5;

        op = 3'b010;
        #5;
        assert(alu_o == (a << b[2:0]))
        else $sformatf("*** ERROR: expecting logical left shift");
        #5;

        op = 3'b011;
        #5;
        assert(alu_o == (a >> b[2:0]))
        else $sformatf("*** ERROR: expecting logical right shift");
        #5;

        op = 3'b100;
        #5;
        assert(alu_o == (a & b))
        else $sformatf("*** ERROR: expecting bitwise and operation");
        #5;

        op = 3'b101;
        #5;
        assert(alu_o == (a | b))
        else $sformatf("*** ERROR: expecting bitwise or operation");
        #5;

        op = 3'b110;
        #5;
        assert(alu_o == (a ^ b))
        else $sformatf("*** ERROR: expecting bitwise xor operation");
        #5;

        op = 3'b111;
        #5;
        assert(alu_o == (a == b))
        else $sformatf("*** ERROR: expecting equals operation");
        #5;
    end

endmodule



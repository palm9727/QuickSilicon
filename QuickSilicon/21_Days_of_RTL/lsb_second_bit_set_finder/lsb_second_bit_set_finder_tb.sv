// LSB second bit set finder testbench

module lsb_second_bit_set_finder_tb ();
    logic[11:0]  vec_i;
    logic[11:0]  second_bit_o;

    // DUT instance
    lsb_second_bit_set_finder #(
        .WIDTH         (12)
    ) LSB_SB_Finder (
        .vec_i         (vec_i),
        .second_bit_o  (second_bit_o)
    );

    // Testing the combinational logic of the Finder
    initial begin
        vec_i = 12'h000;
        #5;
        assert(second_bit_o == 12'h000)
        else $sformatf("*** ERROR: expecting 12'h000");
        #5;

        vec_i = 12'h001;
        #5;
        assert(second_bit_o == 12'h000)
        else $sformatf("*** ERROR: expecting 12'h000");
        #5;

        vec_i = 12'h010;
        #5;
        assert(second_bit_o == 12'h000)
        else $sformatf("*** ERROR: expecting 12'h000");
        #5;

        vec_i = 12'h100;
        #5;
        assert(second_bit_o == 12'h000)
        else $sformatf("*** ERROR: expecting 12'h000");
        #5;

        vec_i = 12'h800;
        #5;
        assert(second_bit_o == 12'h000)
        else $sformatf("*** ERROR: expecting 12'h000");
        #5;

        vec_i = 12'h003;
        #5;
        assert(second_bit_o == 12'h002)
        else $sformatf("*** ERROR: expecting 12'h002");
        #5;

        vec_i = 12'hff0;
        #5;
        assert(second_bit_o == 12'h020)
        else $sformatf("*** ERROR: expecting 12'h020");
        #5;

        vec_i = 12'hf00;
        #5;
        assert(second_bit_o == 12'h200)
        else $sformatf("*** ERROR: expecting 12'h000");
        #5;

        vec_i = 12'hc00;
        #5;
        assert(second_bit_o == 12'h800)
        else $sformatf("*** ERROR: expecting 12'h800");
        #5;

        $finish;
    end

endmodule



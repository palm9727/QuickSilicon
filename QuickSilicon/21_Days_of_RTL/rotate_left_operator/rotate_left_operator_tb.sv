// Rotate Left Operator testbench

module rotate_left_operator_tb ();
    logic[15:0]  data_i;
    logic[3:0]   shamt_i;
    logic[15:0]  result_by_shift_o;
    logic[15:0]  result_by_borders_o;

    // DUT instance
    rotate_left_operator #(
        .SIZE         (16),
        .SHAMT_SIZE   (4)
    ) RLO (
        .data_i               (data_i),
        .shamt_i              (shamt_i),
        .result_by_shift_o    (result_by_shift_o),
        .result_by_borders_o  (result_by_borders_o)
    );

    // Testing the combinational logic of the Finder
    initial begin
        data_i = 16'h0001;
        shamt_i = 4'h1;
        #5;
        assert(result_by_shift_o == 16'h0002)
        else $sformatf("*** ERROR: expecting 16'h0002");
        assert(result_by_borders_o == 16'h0002)
        else $sformatf("*** ERROR: expecting 16'h0002");
        #5;

        data_i = 16'h8000;
        shamt_i = 4'h1;
        #5;
        assert(result_by_shift_o == 16'h0001)
        else $sformatf("*** ERROR: expecting 16'h0001");
        assert(result_by_borders_o == 16'h0001)
        else $sformatf("*** ERROR: expecting 16'h0001");
        #5;

        data_i = 16'h4000;
        shamt_i = 4'h1;
        #5;
        assert(result_by_shift_o == 16'h8000)
        else $sformatf("*** ERROR: expecting 16'h8000");
        assert(result_by_borders_o == 16'h8000)
        else $sformatf("*** ERROR: expecting 16'h8000");
        #5;

        data_i = 16'h0008;
        shamt_i = 4'h1;
        #5;
        assert(result_by_shift_o == 16'h0010)
        else $sformatf("*** ERROR: expecting 16'h0010");
        assert(result_by_borders_o == 16'h0010)
        else $sformatf("*** ERROR: expecting 16'h0010");
        #5;

        data_i = 16'h0008;
        shamt_i = 4'hf;
        #5;
        assert(result_by_shift_o == 16'h0004)
        else $sformatf("*** ERROR: expecting 16'h0004");
        assert(result_by_borders_o == 16'h0004)
        else $sformatf("*** ERROR: expecting 16'h0004");
        #5;

        $finish;
    end

endmodule



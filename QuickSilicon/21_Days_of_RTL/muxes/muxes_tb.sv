// A simple TB for the Muxes

module muxes_tb ();
    logic[3:0] a_i;
    logic[3:0] sel_i;
    logic      y_ter_o;
    logic      y_case_o;
    logic      y_ifelse_o;
    logic      y_loop_o;
    logic      y_aor_o;

    // DUT instance
    muxes MUXES (
        .a_i        (a_i),
        .sel_i      (sel_i),
        .y_ter_o    (y_ter_o),
        .y_case_o   (y_case_o),
        .y_ifelse_o (y_ifelse_o),
        .y_loop_o   (y_loop_o),
        .y_aor_o    (y_aor_o)
    );

    // Testing the combinational logic of the muxes
    initial begin
        a_i = 4'b0011;
        sel_i = 4'b0010;
        #20;

        #5;
        assert(y_ter_o == 1'b1)
        else $sformatf("*** ERROR: expecting 1'b1 as output");
        assert(y_case_o == 1'b1)
        else $sformatf("*** ERROR: expecting 1'b1 as output");
        assert(y_ifelse_o == 1'b1)
        else $sformatf("*** ERROR: expecting 1'b1 as output");
        assert(y_loop_o == 1'b1)
        else $sformatf("*** ERROR: expecting 1'b1 as output");
        assert(y_aor_o == 1'b1)
        else $sformatf("*** ERROR: expecting 1'b1 as output");
        #5;

        a_i = 4'b0011;
        sel_i = 4'b1000;
        #20;

        #5;
        assert(y_ter_o == 1'b0)
        else $sformatf("*** ERROR: expecting 1'b0 as output");
        assert(y_case_o == 1'b0)
        else $sformatf("*** ERROR: expecting 1'b0 as output");
        assert(y_ifelse_o == 1'b0)
        else $sformatf("*** ERROR: expecting 1'b0 as output");
        assert(y_loop_o == 1'b0)
        else $sformatf("*** ERROR: expecting 1'b0 as output");
        assert(y_aor_o == 1'b0)
        else $sformatf("*** ERROR: expecting 1'b0 as output");
        #5;

        a_i = 4'b0011;
        sel_i = 4'b0001;
        #20;

        #5;
        assert(y_ter_o == 1'b1)
        else $sformatf("*** ERROR: expecting 1'b1 as output");
        assert(y_case_o == 1'b1)
        else $sformatf("*** ERROR: expecting 1'b1 as output");
        assert(y_ifelse_o == 1'b1)
        else $sformatf("*** ERROR: expecting 1'b1 as output");
        assert(y_loop_o == 1'b1)
        else $sformatf("*** ERROR: expecting 1'b1 as output");
        assert(y_aor_o == 1'b1)
        else $sformatf("*** ERROR: expecting 1'b1 as output");
        #5;
    end

endmodule



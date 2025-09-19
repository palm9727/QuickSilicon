// A simple TB for the fixed priority arbiter

module fixed_priority_arbiter_tb ();
    logic[3:0] req_i;
    logic[3:0] gnt_o;

    // DUT instance
    fixed_priority_arbiter #(
        .NUM_PORTS  (4)
    ) FPA (
        .req_i      (req_i),
        .gnt_o      (gnt_o)
    );

    // Testing the combinational logic of the fixed priority arbiter
    initial begin
        req_i = 4'b1011;
        #20;
        assert(gnt_o == 4'b0001)
        else $sformatf("*** ERROR: expecting 4'b0001 as output");
        #5;

        req_i = 4'b1000;
        #20;
        assert(gnt_o == 4'b1000)
        else $sformatf("*** ERROR: expecting 4'b1000 as output");
        #5;

        req_i = 4'b1010;
        #20;
        assert(gnt_o == 4'b0010)
        else $sformatf("*** ERROR: expecting 4'b0010 as output");
        #5;

        req_i = 4'b1100;
        #20;
        assert(gnt_o == 4'b0100)
        else $sformatf("*** ERROR: expecting 4'b0010 as output");
        #5;
        
        $finish;
    end

endmodule



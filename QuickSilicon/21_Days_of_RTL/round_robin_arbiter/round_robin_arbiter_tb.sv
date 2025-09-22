// Simple Round Tobin Arbiter Testbench

module round_robin_arbiter_tb ();
    // DUT signals
    logic       clk;
    logic       reset;
    logic[3:0]  req_i;
    logic[3:0]  gnt_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;

    // DUT instance
    round_robin_arbiter RR_ARBITER (
        .clk              (clk),
        .reset            (reset),
        .req_i            (req_i),
        .gnt_o            (gnt_o)
    );

    // 100 MHz Clock
    initial begin
        #100ns; //? wait 100 ns before starting clock (after inputs have settled)
        clk = 0;
        forever begin
            #5ns clk = ~clk;
        end
    end

    task pdla(int cycles = 1);
        repeat (cycles)
        @(posedge clk);
    endtask

    // Used to pass time with clock cycles
    task dla(int cycles = 1);
        repeat (cycles)
        @(negedge clk);
    endtask

    // Pass time with a 1ns delay
    task sdla(int cycles = 1);
        dla(cycles);
        #1ns;  //? To ensure driving is after monitoring
    endtask

    // Print message with time
    function void pmsg(input string msg);
        $display("%s at time %0t", msg, $time);
    endfunction //? msg

    // Record Errors!
    function void incErr(input string msg);
        pmsg(msg);
        errors += 1;
        if (errors > 10) begin
            pmsg("*** MAX ERROR COUNT of 10 exceeded: exiting");
            $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
            $finish;
        end
    endfunction // incErr

    task sendRequests();
        // Wait for a few negative edges of the clock and then start setting the input
        pdla(4);
        flag = 1;

        req_i = 4'b1011;
        pdla(1);

        req_i = 4'b1000;
        pdla(1);

        req_i = 4'b1010;
        pdla(1);

        req_i = 4'b1100;
        pdla(1);

        req_i = 4'b1011;
        pdla(1);

        req_i = 4'b1000;
        pdla(1);

        req_i = 4'b0001;
        pdla(1);
    endtask

    task chkArbiter();
        // Checks the output at the falling edge of the clock
        dla(4);
        flag2 = 1;

        assert(gnt_o == 4'b0001)
        else $sformatf("*** ERROR: expecting 4'b0001 as output");
        dla(1);

        assert(gnt_o == 4'b1000)
        else $sformatf("*** ERROR: expecting 4'b1000 as output");
        dla(1);

        assert(gnt_o == 4'b0010)
        else $sformatf("*** ERROR: expecting 4'b0010 as output");
        dla(1);

        assert(gnt_o == 4'b0100)
        else $sformatf("*** ERROR: expecting 4'b0100 as output");
        dla(1);

        assert(gnt_o == 4'b1000)
        else $sformatf("*** ERROR: expecting 4'b1000 as output");
        dla(1);

        assert(gnt_o == 4'b1000)
        else $sformatf("*** ERROR: expecting 4'b1000 as output");
        dla(1);

        assert(gnt_o == 4'b0001)
        else $sformatf("*** ERROR: expecting 4'b0001 as output");
        dla(1);
    endtask

    task TestArbiter;
        begin : Round_Robin_Arbiter_test
            fork
                sendRequests();
                chkArbiter();
            join
        end
    endtask

    initial begin
        errors = 0;
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of Simulation ***");

        // Initial values
        reset = 0;
        req_i = 4'h0;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test Arbiter
        TestArbiter();

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
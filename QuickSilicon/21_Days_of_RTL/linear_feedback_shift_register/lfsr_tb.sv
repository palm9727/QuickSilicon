// Linear Feedback Shift Register Testbench

module lfsr_tb ();
    // DUT signals
    logic      clk;
    logic      reset;
    logic[3:0] lfsr_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;
    int flag3;

    // DUT instance
    lfsr LFSR (
        .clk              (clk),
        .reset            (reset),
        .lfsr_o           (lfsr_o)
    );

    // 100 MHz Clock
    initial begin
        #100ns; //? wait 100 ns before starting clock (after inputs have settled)
        clk = 0;
        forever begin
            #5ns clk = ~clk;
        end
    end

    // Used to pass time with clock cycles (to the neg edge of the clk)
    task dla(int cycles = 1);
        repeat (cycles)
        @(negedge clk);
    endtask

    // Pass time with a 1ns delay (after the neg edge of the clk)
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

    task startTest();
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(4);
        flag = 1;

        // Start system
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        sdla(18);
    endtask

    task chkLFSR();
        // Checks the data at the falling edge of the clock
        dla(5);
        flag2 = 1;

        for (int i = 0; i < 20; i++) begin
            
            if (i == 8) begin
                flag3 = 1;
                assert(lfsr_o == 4'b1000)
                else incErr($sformatf("*** ERROR: expecting 1000"));
            end else if (i == 11) begin
                assert(lfsr_o == 4'b0101)
                else incErr($sformatf("*** ERROR: expecting 0101"));
            end else if (i == 15) begin
                assert(lfsr_o == 4'b0001)
                else incErr($sformatf("*** ERROR: expecting 0001"));
            end

            dla(1);
        end

        dla(1);
    endtask

    task TestLFSR;
        begin : LFSR_Test
            fork
                startTest();
                chkLFSR();
            join
        end
    endtask

    initial begin
        errors = 0;
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of Simulation ***");

        // Initial values
        reset = 0;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test LFSR
        TestLFSR();

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
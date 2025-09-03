// Odd Counter Testbench

module odd_counter_tb ();
    // DUT signals
    logic        clk;
    logic        reset;
    logic[7:0]   cnt_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;

    // DUT instance
    odd_counter COUNTER (
        .clk              (clk),
        .reset            (reset),
        .cnt_o              (cnt_o)
    );

    // 100 MHz Clock
    initial begin
        #100ns; //? wait 100 ns before starting clock (after inputs have settled)
        clk = 0;
        forever begin
            #5ns clk = ~clk;
        end
    end

    // Used to pass time with clock cycles
    // Moves time to the next negative edge of the clock
    task dla(int cycles = 1);
        repeat (cycles)
        @(negedge clk);
    endtask

    // Pass time with a 1ns delay
    // Moves time to 1ns after the negative edge of the clock
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

    task startCounter();
        // Reset Counter
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);
        flag = 1;

        // Run Counter for the next 9 cycles
        sdla(9);
    endtask

    task chkCounter();
        // Checks the data at the falling edge of the clock
        dla(4);
        flag2 = 1;

        assert(cnt_o == 1)
        else incErr($sformatf("*** ERROR: expecting count of 1"));
        dla(1);

        assert(cnt_o == 3)
        else incErr($sformatf("*** ERROR: expecting count of 1"));
        dla(1);

        assert(cnt_o == 5)
        else incErr($sformatf("*** ERROR: expecting count of 1"));
        dla(1);
    endtask

    task TestOddCounter;
        begin : Odd_Counter_Test
            fork
                startCounter();
                chkCounter();
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

        // Test Edge Detector
        TestOddCounter();

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
// Self Reloading Counter Testbench

module self_reloading_counter_tb ();
    // DUT signals
    logic        clk;
    logic        reset;
    logic        load_i;
    logic[3:0]   load_val_i;
    logic[3:0]   count_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;

    // DUT instance
    self_reloading_counter SR_CTR (
        .clk              (clk),
        .reset            (reset),
        .load_i           (load_i),
        .load_val_i       (load_val_i),
        .count_o          (count_o)
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

    task startCounter();
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(4);
        flag = 1;

        // Restarting the counter
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Running the counter till it rolls-over back to 0
        sdla(20);

        // Running the counter till it rolls-over to the last loaded value
        load_i = 1'b1;
        sdla(21);
    endtask

    task chkCounter();
        // Checks the data at the falling edge of the clock
        dla(5);
        flag2 = 1;

        dla(18);
        assert(count_o == 4'h0)
        else incErr($sformatf("*** ERROR: expecting count_o of 0"));

        dla(16);
        assert(count_o == 4'h7)
        else incErr($sformatf("*** ERROR: expecting count_o of 7"));

        dla(1);
    endtask

    task TestCounter;
        begin : Test_Counter
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
        load_i = 1'b0;
        load_val_i = 4'h7;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test Counter
        TestCounter();

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
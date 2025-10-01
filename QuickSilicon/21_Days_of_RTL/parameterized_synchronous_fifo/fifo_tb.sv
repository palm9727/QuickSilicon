// Parameterized Synchronous Fifo Testbench

module fifo_tb ();
    // DUT signals
    logic      clk;
    logic      reset;
    logic      push_i;
    logic[3:0] push_data_i;
    logic      pop_i;
    logic[3:0] pop_data_o;
    logic      full_o;
    logic      empty_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;

    // DUT instance
    fifo #(
        .DEPTH  (4),
        .DATA_W (4)
    ) FIFO (
        .clk              (clk),
        .reset            (reset),
        .push_i           (push_i),
        .push_data_i      (push_data_i),
        .pop_i            (pop_i),
        .pop_data_o       (pop_data_o),
        .full_o           (full_o),
        .empty_o          (empty_o)
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

        // Fill FIFO
        push_i = 1'b1;
        push_data_i = 4'hd;
        sdla(1);
        push_data_i = 4'he;
        sdla(1);
        push_data_i = 4'ha;
        sdla(1);
        push_data_i = 4'hd;
        sdla(1);

        push_i = 1'b0;
        sdla(1);

        // Empty FIFO
        pop_i = 1'b1;
        sdla(4);

        pop_i = 1'b0;
        sdla(1);

        // Fill and Empty FIFO
        push_i = 1'b1;      // Start pushing data
        push_data_i = 4'hd;
        sdla(1);
        push_data_i = 4'he;
        sdla(1);
        push_data_i = 4'ha;
        sdla(1);
        push_data_i = 4'hd;
        sdla(1);
        pop_i = 1'b1;       // Start poping data!
        push_data_i = 4'hb;
        sdla(1);
        push_data_i = 4'he;
        sdla(1);
        push_data_i = 4'he;
        sdla(1);
        push_data_i = 4'hf;
        sdla(1);            
        push_i = 1'b0;      // Stop pushing data
        sdla(4);
        pop_i = 1'b0;       // Stop poping data!
        sdla(1);
    endtask

    task chkFIFO();
        // Checks the data at the falling edge of the clock
        dla(4);
        flag2 = 1;
        assert(empty_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, empty_o));
        dla(1);
        assert(empty_o == 1'b0)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b0, empty_o));

        dla(3);
        assert(full_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, full_o));

        dla(2);
        assert(pop_data_o == 4'hd)
        else incErr($sformatf("*** ERROR: expecting %0x, got %0x instead", 4'hd, pop_data_o));
        dla(1);
        assert(pop_data_o == 4'he)
        else incErr($sformatf("*** ERROR: expecting %0x, got %0x instead", 4'he, pop_data_o));
        dla(1);
        assert(pop_data_o == 4'ha)
        else incErr($sformatf("*** ERROR: expecting %0x, got %0x instead", 4'ha, pop_data_o));
        dla(1);
        assert(pop_data_o == 4'hd)
        else incErr($sformatf("*** ERROR: expecting %0x, got %0x instead", 4'hd, pop_data_o));
        assert(empty_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, empty_o));
        dla(1);
    endtask

    task TestFIFO;
        begin : FIFO_Test
            fork
                startTest();
                chkFIFO();
            join
        end
    endtask

    initial begin
        errors = 0;
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of Simulation ***");

        // Initial values
        reset = 0;
        push_i = 1'b0;
        push_data_i = 4'h0;
        pop_i = 1'b0;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test FIFO
        TestFIFO();

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
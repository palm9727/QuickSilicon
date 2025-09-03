// Simple Shift Register Testbench

module shift_register_tb ();
    // DUT signals
    logic      clk;
    logic      reset;
    logic      x_i;
    logic[3:0] sr_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;
    int flag3;

    // DUT instance
    shift_register SR (
        .clk              (clk),
        .reset            (reset),
        .x_i              (x_i),
        .sr_o             (sr_o)
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

    task sendData(input logic [19:0] data_inputs);
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(4);
        flag = 1;

        for (int i = 0; i < 20; i++) begin
            x_i = data_inputs[i];
            sdla(1);
        end

        sdla(1);
    endtask

    task chkShiftRegister(input logic [19:0] data_inputs);
        // Checks the data at the falling edge of the clock
        dla(5);
        flag2 = 1;

        for (int i = 0; i < 20; i++) begin
            if (i == 5) begin
                flag3 = 1;
                assert(sr_o == 4'b0001)
                else incErr($sformatf("*** ERROR: expecting 0001"));
            end else if (i == 10) begin
                assert(sr_o == 4'b1110)
                else incErr($sformatf("*** ERROR: expecting 1110"));
            end else if (i == 15) begin
                assert(sr_o == 4'b0001)
                else incErr($sformatf("*** ERROR: expecting 0001"));
            end

            dla(1);
        end

        dla(1);
    endtask

    task TestShiftRegister;
        begin : Shift_Register_Test
            logic [19:0] data_inputs = 20'b11111000001111100000;
            fork
                sendData(data_inputs);
                chkShiftRegister(data_inputs);
            join
        end
    endtask

    initial begin
        errors = 0;
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of Simulation ***");

        // Initial values
        reset = 0;
        x_i = 0;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test Shift Register
        TestShiftRegister();

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end


endmodule

module dff_with_en_tb ();
    // DUT signals
    logic   clk;
    logic   reset;
    logic   d_i;
    logic   en_i;
    logic   q_o;

    // Testbench variables
    int errors;

    // DUT instance
    dff_with_en DFF_with_EN (
        .clk          (clk),
        .reset        (reset),
        .d_i          (d_i),
        .en_i    (en_i),
        .q_o  (q_o)
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

        for (int i = 0; i < 20; i++) begin
            d_i = data_inputs[i];
            if (i > 8) begin
                en_i = 1'b1;
            end
            if (i > 13) begin
                reset = 1'b1;
            end
            sdla(1);
        end

        reset = 1'b0;

        sdla(1);
    endtask

    task chkSyncOutputs(input logic [19:0] data_inputs);
        // To check the data at the rising edge of the clock
        dla(5); 

        for (int i = 0; i < 20; i++) begin

            if (reset) begin
                assert(q_o == 1'b0)
                else incErr($sformatf("*** ERROR: expecting %0d, got %0d instead", 1'b0, q_o));
            end
            else begin
                if (en_i) begin
                    assert(q_o == data_inputs[i])
                    else incErr($sformatf("*** ERROR: expecting bit %0d of %0x which is a %0d, got %0d instead", i, data_inputs, data_inputs[i], q_o));
                end
            end

            dla(1);
        end

        dla(1);
    endtask

    task TestFlipflops;
        begin : DFFs_Test
            logic [19:0] data_inputs = 20'b00000111110000011111;
            fork
                sendData(data_inputs);
                chkSyncOutputs(data_inputs);
            join
        end
    endtask

    initial begin
        errors = 0;
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of Simulation ***");

        // Initial values
        reset = 0;
        d_i = 0;
        en_i = 0;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test DFFs
        TestFlipflops();

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
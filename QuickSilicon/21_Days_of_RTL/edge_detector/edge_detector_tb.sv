// Rising and Falling Edge Detector Testbench

module edge_detector_tb ();
    // DUT signals
    logic   clk;
    logic   reset;
    logic   a_i;
    logic   rising_edge_o;
    logic   falling_edge_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;

    // DUT instance
    edge_detector RF_EDGE_DETECTOR (
        .clk              (clk),
        .reset            (reset),
        .a_i              (a_i),
        .rising_edge_o    (rising_edge_o),
        .falling_edge_o   (falling_edge_o)
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
            a_i = data_inputs[i];
            sdla(1);
        end

        sdla(1);
    endtask

    task chkEdgeDetectors(input logic [19:0] data_inputs);
        // Checks the data at the falling edge of the clock
        dla(5);
        flag = 1;

        for (int i = 0; i < 20; i++) begin
            if (i == 5) begin
                flag2 = 1;
                assert(rising_edge_o == 1)
                else incErr($sformatf("*** ERROR: expecting rising_edge_o pulse"));
            end else if (i == 10) begin
                assert(falling_edge_o == 1)
                else incErr($sformatf("*** ERROR: expecting falling_edge_o pulse"));
            end else if (i == 15) begin
                assert(rising_edge_o == 1)
                else incErr($sformatf("*** ERROR: expecting rising_edge_o pulse"));
            end

            dla(1);
        end

        dla(1);
    endtask

    task TestEdgeDetector;
        begin : Edge_Detector_Test
            logic [19:0] data_inputs = 20'b11111000001111100000;
            fork
                sendData(data_inputs);
                chkEdgeDetectors(data_inputs);
            join
        end
    endtask

    initial begin
        errors = 0;
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of Simulation ***");

        // Initial values
        reset = 0;
        a_i = 0;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test Edge Detector
        TestEdgeDetector();

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
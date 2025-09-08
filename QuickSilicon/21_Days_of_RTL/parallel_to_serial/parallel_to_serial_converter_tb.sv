// Parallel to Serial Converter Testbench

module parallel_to_serial_converter_tb ();
    // DUT signals
    logic       clk;
    logic       reset;
    logic       empty_o;
    logic[3:0]  parallel_i;
    logic       serial_o;
    logic       valid_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;

    // DUT instance
    parallel_to_serial_converter PS_Converter (
        .clk              (clk),
        .reset            (reset),
        .empty_o          (empty_o),
        .parallel_i       (parallel_i),
        .serial_o         (serial_o),
        .valid_o          (valid_o)
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

    task sendData(input logic [3:0] data_inputs);
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(4);
        flag = 1;

        parallel_i = data_inputs;

        sdla(20);
    endtask

    task chkConverter(input logic [3:0] data_inputs);
        // Checks the data at the falling edge of the clock
        dla(5);
        flag2 = 1;

        for (int i = 0; i < 4; i++) begin
            assert(serial_o == data_inputs[i])
            else incErr($sformatf("*** ERROR: expecting %0d, got %0d instead", data_inputs[i], serial_o));

            dla(1);
        end

        dla(20);
    endtask

    task TestConverter;
        begin : Parallel_to_Serial_test
            logic [3:0] data_inputs = 4'b1101;
            fork
                sendData(data_inputs);
                chkConverter(data_inputs);
            join
        end
    endtask

    initial begin
        errors = 0;
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of Simulation ***");

        // Initial values
        reset = 0;
        parallel_i = 4'h0;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test Converter
        TestConverter();

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
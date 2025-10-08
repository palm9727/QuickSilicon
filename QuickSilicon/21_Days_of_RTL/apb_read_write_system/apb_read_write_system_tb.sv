// APB Read/Write System Testbench

module apb_read_write_system_tb ();
    // DUT signals
    logic       clk;
    logic       reset;

    logic       read_i;
    logic       write_i;

    logic       rd_valid_o;
    logic[31:0] rd_data_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;

    // DUT instance
    apb_read_write_system APB_RW_SYSTEM (
        .clk              (clk),
        .reset            (reset),

        .read_i           (read_i),
        .write_i          (write_i),

        .rd_valid_o       (rd_valid_o),
        .rd_data_o        (rd_data_o)
    );

    // 100 MHz Clock
    initial begin
        #100ns; //? wait 100 ns before starting clock (after inputs have settled)
        clk = 0;
        forever begin
            #5ns clk = ~clk;
        end
    end

    //Used to pass time to the positive edge of the clock
    task pdla(int cycles = 1);
        repeat (cycles)
        @(posedge clk);
    endtask

    // Used to pass time to the negative edge of the clock
    task dla(int cycles = 1);
        repeat (cycles)
        @(negedge clk);
    endtask

    // Pass time with a 1ns delay after the negative edge of the clock
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

    task doTest();
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(5);
        flag = 1;

        for (int i = 0; i < 8; i++) begin
          read_i = 0;
          write_i = 1;
          sdla(1);
          read_i = 1;
          write_i = 0;
          sdla(1);
        end

        read_i = 0;
        write_i = 0;
        sdla(64);
    endtask

    task chkSystem();
        // Checks the output at the falling edge of the clock
        dla(5);
        flag2 = 1;
        dla(17);
        dla(4);

        for (int i = 0; i < 16; i++) begin
          assert(rd_valid_o == 1'b1)
          else incErr($sformatf("***paddr_o ERROR: expecting %0b, got %0b instead", 1'b1, rd_valid_o));
          dla(4);
        end

        dla(1);
    endtask

    task TestReadWriteSystem();
        begin : Testing_Read_Write_System
            fork
                doTest();
                chkSystem();
            join
        end
    endtask

    initial begin
        errors = 0;
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of Simulation ***");

        // Initial values
        reset = 0;
        read_i = 0;
        write_i = 0;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test Read/Write System
        TestReadWriteSystem();

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
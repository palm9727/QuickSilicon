// Simple Memory Interface Testbench

module memory_interface_tb ();
    // DUT signals
    logic       clk;
    logic       reset;

    logic       req_i;
    logic       req_rnw_i;
    logic[3:0]  req_addr_i;
    logic[31:0] req_wdata_i;
    logic       req_ready_o;
    logic[31:0] req_rdata_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;

    logic[31:0] saved_data;

    // DUT instance
    memory_interface MI (
        .clk              (clk),
        .reset            (reset),

        .req_i            (req_i),
        .req_rnw_i        (req_rnw_i),
        .req_addr_i       (req_addr_i),
        .req_wdata_i      (req_wdata_i),
        .req_ready_o      (req_ready_o),
        .req_rdata_o      (req_rdata_o)
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

    task writeData(input logic [31:0] data);
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(5);
        req_i = 1'b1;
        req_rnw_i = 1'b0;
        req_addr_i = 4'hf;
        sdla(2);

        if (req_ready_o) begin
          req_i = 1'b0;
          req_wdata_i = 32'hdeadcafe;
          sdla(1);
        end

        req_addr_i = 4'h0;
        req_wdata_i = 32'h00000000;
        sdla(1);
    endtask

    task chkWrite();
        // Checks the output at the falling edge of the clock
        dla(5);
        flag = 1;
        dla(2);

        // Checking signal during ACCESS state
        assert(req_ready_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, req_ready_o));
        dla(1);

    endtask

    task doWrite(input logic [31:0] data);
        begin : Testing_MEM_READ
            fork
                writeData(data);
                chkWrite();
            join
        end
    endtask

    task readData(output logic [31:0] data);
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(5);
        req_i = 1'b1;
        req_rnw_i = 1'b1;
        req_addr_i = 4'hf;
        sdla(2);

        if (req_ready_o) begin
          req_i = 1'b0;
          data = req_rdata_o;
          sdla(1);
        end

        req_rnw_i = 1'b0;
        req_addr_i = 4'h0;
        sdla(1);
    endtask

    task chkRead(input logic [31:0] data);
        // Checks the output at the falling edge of the clock
        dla(5);
        flag2 = 1;
        dla(2);

        // Checking signals during ACCESS state
        assert(req_ready_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, req_ready_o));
        assert(req_rdata_o == 32'hdeadcafe)
        else incErr($sformatf("*** ERROR: expecting %0x, got %0x instead", 32'hdeadcafe, req_rdata_o));
        dla(1);

    endtask

    task doRead(output logic [31:0] data_to_update, input logic [31:0] data_to_use);
        begin : Testing_MEM_READ
            fork
                readData(data_to_update);
                chkRead(data_to_use);
            join
        end
    endtask

    task TestMemoryInterface(output logic [31:0] data_o, input logic [31:0] data_i);
        begin : Testing_Memory_Interface
            for (int i = 0; i < 3; i++) begin
                doWrite(data_i);
                sdla(5);
                doRead(data_o, data_i);
                sdla(5);
            end
        end
    endtask

    initial begin
        errors = 0;
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of Simulation ***");

        // Initial values
        reset = 0;
        req_i = 1'b0;
        req_rnw_i = 1'b0;
        req_addr_i = 4'h0;
        req_wdata_i = 32'h00000000;

        saved_data = 32'h00000001;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test Memory Interface
        TestMemoryInterface(saved_data, saved_data);

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
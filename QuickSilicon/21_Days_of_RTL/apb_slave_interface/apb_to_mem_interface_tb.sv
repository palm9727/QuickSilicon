// APB Slave to Memory Interface Testbench

module apb_to_mem_interface_tb ();
    // DUT signals
    logic       clk;
    logic       reset;

    logic       psel_i;
    logic       penable_i;
    logic[9:0]  paddr_i;
    logic       pwrite_i;
    logic[31:0] pwdata_i;
    logic[31:0] prdata_o;
    logic       pready_o;

    // Testbench variables
    int errors;
    int flag;
    int flag2;

    logic[31:0] saved_data;

    // DUT instance
    apb_to_mem_interface APB_to_MEM (
        .clk              (clk),
        .reset            (reset),

        .psel_i            (psel_i),
        .penable_i         (penable_i),
        .paddr_i           (paddr_i),
        .pwrite_i          (pwrite_i),
        .pwdata_i          (pwdata_i),
        .prdata_o          (prdata_o),
        .pready_o          (pready_o)
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

    task writeData(input logic [31:0] data, int i);
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(5);
        paddr_i = 10'b0000001111;
        pwrite_i = 1'b1;
        psel_i = 1'b1;
        pwdata_i = data + i;
        pdla(2);

        penable_i = 1'b1;
        pdla(1);

        while (pready_o != 1'b1) begin
          pdla(1);
        end

        sdla(1);
        paddr_i = 10'b0000000000;
        pwrite_i = 1'b0;
        psel_i = 1'b0;
        penable_i = 1'b0;
        pwdata_i = 32'h00000000;
        sdla(1);
    endtask

    task chkWrite();
        // Checks the output at the falling edge of the clock
        dla(5);
        flag = 1;
        dla(4);

        assert(pready_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, pready_o));
        dla(1);

    endtask

    task doWrite(input logic [31:0] data, int i);
        begin : Testing_APB_to_MEM_READ
            fork
                writeData(data, i);
                chkWrite();
            join
        end
    endtask

    task readData(output logic [31:0] data);
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(5);
        paddr_i = 10'b0000001111;
        pwrite_i = 1'b0;
        psel_i = 1'b1;
        pdla(2);

        penable_i = 1'b1;
        pdla(1);

        while (pready_o != 1'b1) begin
          pdla(1);
        end

        data = prdata_o;
        sdla(1);

        paddr_i = 10'b0000000000;
        pwrite_i = 1'b0;
        psel_i = 1'b0;
        penable_i = 1'b0;
        sdla(1);
    endtask

    task chkRead(input logic [31:0] data, int i);
        // Checks the output at the falling edge of the clock
        dla(5);
        flag2 = 1;
        dla(4);

        assert(pready_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, pready_o));
        assert(prdata_o == data + i)
        else incErr($sformatf("*** ERROR: expecting %0x, got %0x instead", data + i, prdata_o));
        dla(1);

    endtask

    task doRead(output logic [31:0] data_to_update, input logic [31:0] data_to_use, int i);
        begin : Testing_APB_to_MEM_READ
            fork
                readData(data_to_update);
                chkRead(data_to_use, i);
            join
        end
    endtask

    task TestAPBToMemoryInterface(output logic [31:0] data_o, input logic [31:0] data_i);
        begin : Testing_APB_to_Memory_Interface
            for (int i = 0; i < 2; i++) begin
                doWrite(data_i, i);
                sdla(5);
                doRead(data_o, data_i, i);
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
        psel_i = 1'b0;
        penable_i = 1'b0;
        paddr_i = 10'b0000000000;
        pwrite_i = 1'b0;
        pwdata_i = 32'h00000000;

        saved_data = 32'hdeadbee0;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test APB to Memory Interface
        TestAPBToMemoryInterface(saved_data, saved_data);

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
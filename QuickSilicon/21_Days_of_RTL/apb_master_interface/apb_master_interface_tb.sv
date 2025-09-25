// APB Master Interface Testbench

module apb_master_interface_tb ();
    // DUT signals
    logic       clk;
    logic       reset;

    logic[1:0]  cmd_i;

    logic       psel_o;
    logic       penable_o;
    logic[31:0] paddr_o;
    logic       pwrite_o;
    logic[31:0] pwdata_o;
    logic       pready_i;
    logic[31:0] prdata_i;

    // Testbench variables
    int errors;
    int flag;
    int flag2;

    logic[31:0] saved_data;

    // DUT instance
    apb_master_interface APB_MI (
        .clk              (clk),
        .reset            (reset),

        .cmd_i            (cmd_i),

        .psel_o           (psel_o),
        .penable_o        (penable_o),
        .paddr_o          (paddr_o),
        .pwrite_o         (pwrite_o),
        .pwdata_o         (pwdata_o),
        .pready_i         (pready_i),
        .prdata_i         (prdata_i)
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

    task readData(input logic [31:0] data);
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(5);
        flag = 1;
        cmd_i = 2'b01;
        sdla(2);

        if (psel_o && penable_o) begin
          cmd_i = 2'b00;
          prdata_i = data;
          pready_i = 1'b1;
          sdla(1);
        end

        prdata_i = 32'h00000000;
        pready_i = 1'b0;
        sdla(1);
    endtask

    task chkRead();
        // Checks the output at the falling edge of the clock
        dla(5);
        flag2 = 1;
        dla(1);

        // Checking signals during SETUP state
        assert(paddr_o == 32'hdeadcafe)
        else incErr($sformatf("*** ERROR: expecting %0x, got %0x instead", 32'hdeadcafe, paddr_o));
        assert(pwrite_o == 1'b0)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b0, pwrite_o));
        assert(psel_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, psel_o));
        assert(penable_o == 1'b0)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b0, penable_o));
        dla(1);

        // Checking signals during ACCESS state
        assert(paddr_o == 32'hdeadcafe)
        else incErr($sformatf("*** ERROR: expecting %0x, got %0x instead", 32'hdeadcafe, paddr_o));
        assert(pwrite_o == 1'b0)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b0, pwrite_o));
        assert(psel_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, psel_o));
        assert(penable_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, penable_o));
        dla(1);

    endtask

    task doRead(input logic [31:0] data);
        begin : Testing_APB_READ
            fork
                readData(data);
                chkRead();
            join
        end
    endtask

    task writeData(output logic [31:0] data);
        // Wait for a few negative edges of the clock and then start setting the input
        sdla(5);
        flag = 1;

        cmd_i = 2'b10;
        sdla(2);

        if (psel_o && penable_o) begin
          cmd_i = 2'b00;
          data = pwdata_o;
          pready_i = 1'b1;
          sdla(1);
        end

        pready_i = 1'b0;
        sdla(1);
    endtask

    task chkWrite(input logic [31:0] data);
        // Checks the output at the falling edge of the clock
        dla(5);
        flag2 = 1;
        dla(1);

        // Checking signals during SETUP state
        assert(paddr_o == 32'hdeadcafe)
        else incErr($sformatf("***paddr_o ERROR: expecting %0x, got %0x instead", 32'hdeadcafe, paddr_o));
        assert(pwrite_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, pwrite_o));
        assert(psel_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, psel_o));
        assert(penable_o == 1'b0)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b0, penable_o));
        assert(pwdata_o == data + 1)
        else incErr($sformatf("***pwdata_o ERROR: expecting %0x, got %0x instead", data + 1, pwdata_o));
        dla(1);

        // Checking signals during ACCESS state
        assert(paddr_o == 32'hdeadcafe)
        else incErr($sformatf("***paddr_o ERROR: expecting %0x, got %0x instead", 32'hdeadcafe, paddr_o));
        assert(pwrite_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, pwrite_o));
        assert(psel_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, psel_o));
        assert(penable_o == 1'b1)
        else incErr($sformatf("*** ERROR: expecting %0b, got %0b instead", 1'b1, penable_o));
        assert(pwdata_o == data + 1)
        else incErr($sformatf("***pwdata_o ERROR: expecting %0x, got %0x instead", data + 1, pwdata_o));
        dla(1);

    endtask

    task doWrite(output logic [31:0] data_to_update, input logic [31:0] data_to_use);
        begin : Testing_APB_WRITE
            fork
                writeData(data_to_update);
                chkWrite(data_to_use);
            join
        end
    endtask

    task TestAPBTransfers(output logic [31:0] data_o, input logic [31:0] data_i);
        begin : Testing_APB_Transfers
            for (int i = 0; i < 3; i++) begin
                doRead(data_i);
                sdla(5);
                doWrite(data_o, data_i);
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
        cmd_i = 2'b00;
        prdata_i = 32'h00000000;
        pready_i = 1'b0;
        saved_data = 32'h00000001;

        // Perform reset on system
        sdla(1);
        reset = 1;
        sdla(3);
        reset = 0;
        sdla(1);

        // Test APB transfers
        TestAPBTransfers(saved_data, saved_data);

        $display("*** Simulation done with %0d errors at time %0t ***", errors, $time);
        $finish;
    end

endmodule
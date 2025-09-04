// Binary to One-Hot Converter Testbench

module binary_to_one_hot_tb ();
    logic[3:0]  bin_i;
    logic[15:0] one_hot_o;

    // DUT instance
    binary_to_one_hot #(
        .BIN_W         (4),
        .ONE_HOT_W     (16)
    ) BTO (
        .bin_i       (bin_i),
        .one_hot_o   (one_hot_o)
    );

    // Testing the combinational logic of the Binary to One Hot Converter
    initial begin
        bin_i = 4'h0;
        #5;

        for (int i = 0; i < 16; i++) begin
          bin_i = i;

          if (i == 0) begin
            assert(one_hot_o == 16'h0001)
            else $sformatf("*** ERROR: expecting 16'h0001");
          end else if (i == 4) begin
            assert(one_hot_o == 16'h0010)
            else $sformatf("*** ERROR: expecting 16'h0001");
          end else if (i == 8) begin
            assert(one_hot_o == 16'h0100)
            else $sformatf("*** ERROR: expecting 16'h0001");
          end else if (i == 12) begin
            assert(one_hot_o == 16'h1000)
            else $sformatf("*** ERROR: expecting 16'h0001");
          end

          #5;
        end

    end

endmodule



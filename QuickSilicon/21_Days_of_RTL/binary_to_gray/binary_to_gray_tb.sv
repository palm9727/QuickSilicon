// Binary to Gray Code Converter Testbench

module binary_to_gray_tb ();
    logic[3:0]  bin_i;
    logic[3:0]  gray_o;

    // DUT instance
    binary_to_gray #(
        .VEC_W         (4)
    ) BTG (
        .bin_i       (bin_i),
        .gray_o      (gray_o)
    );

    // Testing the combinational logic of the Binary to Gray Converter
    initial begin
        bin_i = 4'h0;
        #5;

        for (int i = 0; i < 16; i++) begin
          bin_i = i;

          if (i == 0) begin
            assert(gray_o == 4'b0000)
            else $sformatf("*** ERROR: expecting 4'b0000");
          end else if (i == 4) begin
            assert(gray_o == 4'b0110)
            else $sformatf("*** ERROR: expecting 4'b0110");
          end else if (i == 8) begin 
            assert(gray_o == 4'b1100)
            else $sformatf("*** ERROR: expecting 4'b1100");
          end else if (i == 12) begin 
            assert(gray_o == 4'b1010)
            else $sformatf("*** ERROR: expecting 4'b1010");
          end

          #5;
        end

    end

endmodule



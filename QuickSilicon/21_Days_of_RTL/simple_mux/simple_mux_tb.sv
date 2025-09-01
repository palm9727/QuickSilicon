// A simple TB for mux

module simple_mux_tb ();
    logic a;
    logic b;
    logic sel;
    logic y;

    simple_mux MUX (
        .a_i   (a),
        .b_i   (b),
        .sel_i (sel),
        .y_o   (y)
    );

    initial begin
        a = 1'b0;
        b = 1'b0;
        sel = 1'b0;
        #5;

        for (int i = 0; i < 20; i++) begin
            if (i % 2 == 0) begin
                a = ~a;
            end
            if (i % 3 == 0) begin
                b = ~b;
            end
            if (i % 5 == 0) begin
                sel = ~sel;
            end
            #5;
        end
    end

endmodule



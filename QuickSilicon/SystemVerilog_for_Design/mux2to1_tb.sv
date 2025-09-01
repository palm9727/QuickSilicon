module mux2to1_tb ();
    logic a;
    logic b;
    logic sel;
    logic y;

    mux2to1 MUX (
        .a   (a),
        .b   (b),
        .sel (sel),
        .y   (y)
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
module dff_with_en (
    input   logic   clk,
    input   logic   reset,

    input   logic   d_i,
    input   logic   en_i,

    output  logic   q_o
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            q_o <= 0;
        end
        else begin
            if (en_i) begin
                q_o <= d_i;
            end
        end
    end

endmodule

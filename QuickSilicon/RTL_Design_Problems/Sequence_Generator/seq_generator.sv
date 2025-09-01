// System used to generate the following sequence: 1 0 1 1 1 2 2 3 4 5 7 9 12 ...

module seq_generator (
  input   logic        clk,
  input   logic        reset,

  output  logic [31:0] seq_o
);

  // Registers logic
  logic [31:0] reg_0;
  logic [31:0] reg_1;
  logic [31:0] reg_2;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      reg_0 <= 32'h0; // 0 0 1 0 1 1 1 2 2 3 4 5
      reg_1 <= 32'h0; // 0 1 0 1 1 1 2 2 3 4 5 7
      reg_2 <= 32'h1; // 1 0 1 1 1 2 2 3 4 5 7 9 12
    end else begin
      reg_0 <= reg_1;
      reg_1 <= reg_2;
      reg_2 <= seq_o;
    end
  end

  // Output logic
  assign seq_o = reg_0 + reg_1;

endmodule

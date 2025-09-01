module mux2to1 (
  input   logic a,
  input   logic b,
  input   logic sel,
  output  logic y
);

  always_comb begin
    if (~sel)
      y = a;
    else
      y = b;
  end

endmodule

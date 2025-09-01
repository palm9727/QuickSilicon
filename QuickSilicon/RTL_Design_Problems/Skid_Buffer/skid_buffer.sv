// First attempt of the skid_buffer based on the waveform example

module skid_buffer (
  input   logic        clk,
  input   logic        reset,

  input   logic        i_valid_i,
  input   logic [7:0]  i_data_i,
  output  logic        i_ready_o,

  input   logic        e_ready_i,
  output  logic        e_valid_o,
  output  logic [7:0]  e_data_o
);

  // Logic for the capture registers and the missed flag
  logic valid_q;
  logic [7:0] data_q;
  logic missed;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      valid_q <= 1'b0;
      data_q <= 8'h00;
      missed <= 1'b0;
    end else begin
      if (i_valid_i & i_ready_o & e_valid_o & ~e_ready_i) begin
        valid_q <= i_valid_i;
        data_q <= i_data_i;
        missed <= 1'b1;
      end else if (e_ready_i) begin
        valid_q <= 1'b0;
        data_q <= 8'h00;
        missed <= 1'b0;
      end
    end
  end

  // Logic for the e_valid_o and e_data_o
  always_comb begin
    e_valid_o = i_valid_i;
    e_data_o = i_data_i;

    if (missed) begin
      e_valid_o = valid_q;
      e_data_o = data_q;
    end
  end

  // Logic for the i_ready_o
//   always_ff @(posedge clk or posedge reset)
//     if (reset)
//       i_ready_o <= 1'b0;
//     else
//       i_ready_o <= e_ready_i;

  assign i_ready_o = ~valid_q;

endmodule

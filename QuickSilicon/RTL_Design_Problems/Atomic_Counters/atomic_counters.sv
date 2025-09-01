// System used to read correctly a 64 bits counter using a 32 bits signal in 2 cycles

module atomic_counters (
  input                   clk,
  input                   reset,
  input                   trig_i,
  input                   req_i,
  input                   atomic_i,
  output logic            ack_o,
  output logic[31:0]      count_o
);

  // Internal counter logic
  logic [63:0] count_q;
  logic [63:0] count;

  always_ff @(posedge clk or posedge reset)
    if (reset)
      count_q[63:0] <= 64'h0;
    else
      count_q[63:0] <= count;

  always_comb begin
    if (trig_i)
      count = count_q + 64'h1;
    else
      count = count_q;
  end

  // MSB counter logic
  logic [31:0] msb_count;

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      msb_count <= 32'h0;
    else if (atomic_i)
      msb_count <= count_q[63:32];
  end

  // Delayed Input signals logic
  logic req_q;
  logic atomic_q;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      req_q <= 1'b0;
      atomic_q <= 1'b0;
    end
    else begin
      req_q <= req_i;
      atomic_q <= atomic_i;
    end
  end
  
  // Acknowledge logic
  assign ack_o = req_q;

  // Allow output logic
  logic allow_output;

  always_ff @(posedge clk) begin
    if (req_i && atomic_i)
      allow_output <= 1'b1;
    else if (!req_i && !atomic_i)
      allow_output <= 1'b0;
  end
  
  // Counter Output logic
  always_comb begin
    if (allow_output)
      if (ack_o)
        if (atomic_q) 
          count_o = count_q[31:0];
        else
          count_o = msb_count;
      else
        count_o = 32'h0;
    else
      count_o = 32'h0;
  end

endmodule


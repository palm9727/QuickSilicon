module perf_counters #(
  parameter WIDTH = 4
) (
  input  logic            clk,
  input  logic            reset,
  input  logic            sw_req_i,
  input  logic            cpu_trig_i,
  output logic[WIDTH-1:0] p_count_o
);

  logic [WIDTH-1:0] cntr_q;
  logic [WIDTH-1:0] nxt_cntr;
  
  always_ff @(posedge clk or posedge reset)
    if (reset)
      cntr_q <= '0;
    else
      cntr_q <= nxt_cntr;

  logic double_in;

  assign double_in = cpu_trig_i & sw_req_i;
  
  assign nxt_cntr = double_in ? 1 :
                    cpu_trig_i ? cntr_q + 1 :
                    sw_req_i ? '0 :
                    cntr_q;
  
  assign p_count_o = sw_req_i ? cntr_q :
                     '0;
  
endmodule

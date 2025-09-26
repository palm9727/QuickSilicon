// A valid/ready based memory interface slave
// valid/ready protocol implemented in a similar way to the APB protocol state machine

module memory_interface (
  input       wire        clk,
  input       wire        reset,

  input       wire        req_i,
  input       wire        req_rnw_i,    // 1 - read, 0 - write
  input       wire[3:0]   req_addr_i,
  input       wire[31:0]  req_wdata_i,
  output      wire        req_ready_o,
  output      wire[31:0]  req_rdata_o
);
  // Output signals
  logic ready;
  logic[31:0] rdata;

  // Memory array logic
  logic [15:0][31:0] mem;
  logic write_enable;

  initial begin
    for (int i = 0; i < 16; i++) begin
      mem[i] = 32'h00000000;
    end
  end

  always_ff @(posedge clk) begin
    if (write_enable) begin
      mem[req_addr_i] <= req_wdata_i;
    end
  end

  // Memory Interface SM logic
  typedef enum logic[1:0] {IDLE, SETUP, ACCESS, ERR='X} state_t;
  state_t cs;
  state_t ns;

  always_ff @(posedge clk) begin
    cs <= ns;
  end

  always_comb begin
    ns = ERR;
    ready = 1'b0;
    rdata = 32'h00000000;
    write_enable = 1'b0;

    if (reset) begin
      ns = IDLE;
    end else begin
      case(cs)
        IDLE: begin
          if (req_i) begin
            ns = SETUP;
          end else begin
            ns = IDLE;
          end
        end
        SETUP: begin // Giving just 1 clok cycle as delay
          ns = ACCESS;
        end
        ACCESS: begin
          ready = 1'b1;

          if (req_rnw_i) begin
            rdata = mem[req_addr_i];
          end else begin
            write_enable = 1'b1;
          end

          if (req_i) begin
            ns = SETUP;
          end else begin
            ns = IDLE;
          end
        end
        default: ns = ERR;
      endcase
    end
  end

  // Output logic
  assign req_ready_o = ready;
  assign req_rdata_o = rdata;

endmodule

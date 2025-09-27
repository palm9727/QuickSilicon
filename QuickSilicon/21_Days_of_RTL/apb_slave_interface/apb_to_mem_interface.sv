// APB Slave to memory interface

module apb_to_mem_interface (
  input         wire        clk,
  input         wire        reset,

  input         wire        psel_i,
  input         wire        penable_i,
  input         wire[9:0]   paddr_i,
  input         wire        pwrite_i,
  input         wire[31:0]  pwdata_i,
  output        wire[31:0]  prdata_o,
  output        wire        pready_o
);
  // APB output signals
  logic[31:0] rdata;
  logic       ready;

  // MEM interface signals
  logic        req_i;
  logic        req_rnw_i; // 1 - read, 0 - write
  logic[3:0]   req_addr_i;
  logic[31:0]  req_wdata_i;
  logic        req_ready_o;
  logic[31:0]  req_rdata_o;

  // MEM Interface instantiation
  memory_interface MI (
    .clk              (clk),
    .reset            (reset),

    .req_i            (req_i),
    .req_rnw_i        (req_rnw_i),
    .req_addr_i       (req_addr_i),
    .req_wdata_i      (req_wdata_i),
    .req_ready_o      (req_ready_o),
    .req_rdata_o      (req_rdata_o)
  );

  // APB slave SM logic
  typedef enum logic[1:0] {IDLE, ACCESS, ERR='X} state_t;
  state_t cs;
  state_t ns;

  always_ff @(posedge clk) begin
    cs <= ns;
  end

  always_comb begin
    ns = ERR;
    ready = 1'b0;
    rdata = 32'h00000000;

    req_i = 1'b0;
    req_rnw_i = 1'b0;
    req_addr_i = 4'h0;
    req_wdata_i = 32'h00000000;

    if (reset) begin
      ns = IDLE;
    end else begin
      case(cs)
        IDLE: begin
          if (psel_i) begin
            ns = ACCESS;
          end else begin
            ns = IDLE;
          end
        end
        ACCESS: begin
          if (psel_i & penable_i) begin
            if (pwrite_i) begin // Write to Memory
              req_i = 1'b1;
              req_rnw_i = 1'b0;
              req_addr_i = paddr_i[3:0];
              req_wdata_i = pwdata_i;

              if (req_ready_o) begin
                req_i = 1'b0; // Helps so that MEM Interface SM doesnt get stuct at ACCESS state
                ready = 1'b1;
                ns = IDLE;
              end else begin
                ns = ACCESS;
              end
            end else begin // Read from Memory
              req_i = 1'b1;
              req_rnw_i = 1'b1;
              req_addr_i = paddr_i[3:0];
              
              if (req_ready_o) begin
                req_i = 1'b0; // Helps so that MEM Interface SM doesnt get stuct at ACCESS state
                rdata = req_rdata_o;
                ready = 1'b1;
                ns = IDLE;
              end else begin
                ns = ACCESS;
              end
            end
          end else begin
            ns = ACCESS;
          end
        end
        default: ns = ERR;
      endcase
    end
  end

  // APB output logic
  assign prdata_o = rdata;
  assign pready_o = ready;

endmodule

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

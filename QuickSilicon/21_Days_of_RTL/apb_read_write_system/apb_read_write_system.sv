// A useless read/write system with the following architecture:
//
//                                    rd_valid_o
//                                        ^
//                                        |
// |-----|    |------|    |------|     |------|
// | ARB | -> | FIFO | -> | APBM | <-> | APBS | => rd_data_o
// |-----|    |------|    |------|     |------|

module apb_read_write_system (
  input       wire        clk,
  input       wire        reset,

  input       wire        read_i,
  input       wire        write_i,

  output      wire        rd_valid_o,
  output      wire[31:0]  rd_data_o
);
  // Fixed Priority Arbiter signals
  logic[1:0] fpa_req;
  logic[1:0] fpa_gnt;

  assign fpa_req = {read_i, write_i};

  // Arbiter giving priority to the writing request
  fixed_priority_arbiter #(
    .NUM_PORTS (2)
  ) FPA (
    .req_i     (fpa_req),
    .gnt_o     (fpa_gnt)
  );

  // FIFO signals
  logic      fifo_push;
  logic[1:0] fifo_push_data;
  logic      fifo_pop;
  logic[1:0] fifo_pop_data;  //? To be used as cmd_i to the APB Master
  logic      fifo_full;
  logic      fifo_empty;

  // FIFO that buffers 16 read/write requests
  fifo #(
    .DEPTH       (16),
    .DATA_W      (2)
  ) FIFO (
    .clk         (clk),
    .reset       (reset),
    .push_i      (fifo_push),
    .push_data_i (fifo_push_data),
    .pop_i       (fifo_pop),
    .pop_data_o  (fifo_pop_data),
    .full_o      (fifo_full),
    .empty_o     (fifo_empty)
  );

  // First Request Logic
  logic fifo_full_q;
  logic first_req;

  always_ff @(posedge clk) begin
    fifo_full_q <= fifo_full;
  end

  assign first_req = fifo_full & ~fifo_full_q;

  // FIFO logic (The system starts poping the FIFO once it gets filled filled!)
  always_comb begin
    fifo_push = 1'b0;
    fifo_push_data = fpa_gnt;
    fifo_pop = 1'b0;

    if (|fpa_gnt) begin
      fifo_push = 1'b1;
    end

    if (~fifo_empty & (ready | first_req)) begin
      fifo_pop = 1'b1;
    end
  end

  // APB Signals
  logic       sel;
  logic       enable;
  logic[3:0]  addr;
  logic       write;
  logic[31:0] wdata;
  logic       ready;
  logic[31:0] rdata;

  // APB Master Instance
  apb_master_interface APB_MASTER (
    .clk              (clk),
    .reset            (reset),

    .cmd_i            (fifo_pop_data),

    .psel_o           (sel),
    .penable_o        (enable),
    .paddr_o          (addr),
    .pwrite_o         (write),
    .pwdata_o         (wdata),
    .pready_i         (ready),
    .prdata_i         (rdata)
  );

  // APB Slave to Memory Interface Instance
  apb_to_mem_interface APB_TO_MEM (
    .clk               (clk),
    .reset             (reset),

    .psel_i            (sel),
    .penable_i         (enable),
    .paddr_i           (addr),
    .pwrite_i          (write),
    .pwdata_i          (wdata),
    .prdata_o          (rdata),
    .pready_o          (ready)
  );

  // Output logic
  assign rd_valid_o = ready;
  assign rd_data_o = rdata;

endmodule

// Priority arbiter
// port[0] - highest priority

module fixed_priority_arbiter #(
  parameter NUM_PORTS = 4
)(
    input       wire[NUM_PORTS-1:0] req_i,
    output      wire[NUM_PORTS-1:0] gnt_o   // One-hot grant signal
);

  // Logic for the intermediate mask
  logic[NUM_PORTS-1:0] intermediate_mask;

  always_comb begin
    intermediate_mask[0] = 1'b0;

    for (int i = 1; i < NUM_PORTS; i++) begin
      intermediate_mask[i] = req_i[i - 1] | intermediate_mask[i - 1];
    end
  end

  // Logic for the mask
  logic[NUM_PORTS-1:0] mask;

  assign mask = ~intermediate_mask;

  // Logic for grant output
  assign gnt_o = req_i & mask;

endmodule

// Parameterized fifo

module fifo #(
  parameter DEPTH   = 4,
  parameter DATA_W  = 1
)(
  input         wire              clk,
  input         wire              reset,

  input         wire              push_i,
  input         wire[DATA_W-1:0]  push_data_i,

  input         wire              pop_i,
  output        wire[DATA_W-1:0]  pop_data_o,

  output        wire              full_o,
  output        wire              empty_o
);

  // FIFO Push and Pop Logic
  logic [DEPTH-1:0] [DATA_W-1:0] mem;
  logic [DATA_W-1:0] pop_data;

  always_ff @(posedge clk) begin
    if (reset) begin
      pop_data <= 0;
      for (int i = 0; i < DEPTH; i++) begin
        mem[i] <= 0;
      end
    end else begin
      if (push_i & ~pop_i) begin
        mem[0] <= push_data_i;
        for (int i = 1; i < DEPTH; i++) begin
          mem[i] <= mem[i-1];
        end
        pop_data <= 0;
      end else if (pop_i & ~push_i) begin
        mem[0] <= 0;
        for (int i = 1; i < DEPTH; i++) begin
          mem[i] <= mem[i-1];
        end
        pop_data <= mem[DEPTH-1];
      end else if (push_i & pop_i) begin
        mem[0] <= push_data_i;
        for (int i = 1; i < DEPTH; i++) begin
          mem[i] <= mem[i-1];
        end
        pop_data <= mem[DEPTH-1];
      end
    end
  end

  assign pop_data_o = pop_data;

  // FIFO Full and Empty Logic
  logic [DEPTH-1:0] mem_used;
  logic [DEPTH-1:0] mem_used_q;

  always_ff @(posedge clk) begin
    mem_used_q <= mem_used;
  end

  always_comb begin
    mem_used = 0;

    if (reset) begin
      mem_used = 0;
    end else begin
      if (push_i) begin
        mem_used[0] = 1;
        for (int i = 1; i < DEPTH; i++) begin
          mem_used[i] = mem_used_q[i-1];
        end
      end else if (pop_i) begin
        mem_used[0] = 0;
        for (int i = 1; i < DEPTH; i++) begin
          mem_used[i] = mem_used_q[i-1];
        end
      end else begin
        mem_used = mem_used_q;
      end
    end
  end

  assign full_o = (mem_used_q == '1) ? 1'b1 : 1'b0;
  assign empty_o = (mem_used_q == 0) ? 1'b1 : 1'b0;

endmodule

// APB Master modified for the read/write system

// cmd_i input decoded as:
//  - 2'b00 - No-op
//  - 2'b01 - Increment the previously read data and store it to 0xF (WRITE)
//  - 2'b10 - Read from address 0xF (READ)

module apb_master_interface (
  input       wire        clk,
  input       wire        reset,

  input       wire[1:0]   cmd_i,

  output      wire        psel_o,
  output      wire        penable_o,
  output      wire[3:0]   paddr_o,
  output      wire        pwrite_o,
  output      wire[31:0]  pwdata_o,
  input       wire        pready_i,
  input       wire[31:0]  prdata_i
);
//   // Reading flag signal
//   logic active_reading;

  // Saved data logic
  logic[31:0] saved_data;

  always_ff @(posedge clk) begin
    if (reset) begin
      saved_data <= 32'h00000000;
    end else begin
      //if ((active_reading) && (penable_o) && (pready_i)) begin // It can safely get the read data from the transfer
      if ((penable_o) && (pready_i)) begin // It can safely get the read data from the transfer
        saved_data <= prdata_i;
      end
    end
  end

  // APB SM signals
  typedef enum logic[1:0] {IDLE, SETUP, ACCESS} state_t;
  state_t cs;
  state_t ns;

  logic sel;
  logic enable;
  logic[3:0] addr;
  logic write;
  logic[31:0] wdata;

//   // Reading flag logic
//   always_ff @(posedge clk) begin
//     if (reset) begin
//       active_reading <= 1'b0;
//     end else begin
//       if ((cmd_i == 2'b10) && (cs == SETUP)) begin
//         active_reading <= 1'b1;
//       end else begin
//         active_reading <= 1'b0;
//       end
//     end
//   end

  // APB SM logic
  always_ff @(posedge clk) begin
    cs <= ns;
  end

  always_comb begin
    ns = IDLE;
    sel = 1'b0;
    enable = 1'b0;
    addr = 4'h0;
    write = 1'b0;
    wdata = 32'h00000000;

    if (reset) begin
      ns = IDLE;
    end else begin
      case(cs)
        IDLE: begin
          if (^cmd_i) begin
            ns = SETUP;
          end
        end
        SETUP: begin
          sel = 1'b1;
          addr = 4'hf;

          if (cmd_i == 2'b01) begin // Write transfer 
            write = 1'b1;
            wdata = saved_data + 32'h00000001;
          end

          ns = ACCESS;
        end
        ACCESS: begin
          sel = 1'b1;
          enable = 1'b1;
          addr = 4'hf;

          if (cmd_i == 2'b01) begin // Write transfer
            write = 1'b1;
            wdata = saved_data + 32'h00000001;
          end

          if (pready_i) begin
            if (cmd_i) begin
              ns = SETUP;
            end else begin
              ns = IDLE;
            end
          end else begin
            ns = ACCESS;
          end
        end
        default: ns = IDLE;
      endcase
    end
  end

  assign psel_o = sel;
  assign penable_o = enable;
  assign paddr_o = addr;
  assign pwrite_o = write;
  assign pwdata_o = wdata;

endmodule

// APB Slave to memory interface modified for the read/write system

module apb_to_mem_interface (
  input         wire        clk,
  input         wire        reset,

  input         wire        psel_i,
  input         wire        penable_i,
  input         wire[3:0]   paddr_i,
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
              req_addr_i = paddr_i;
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
              req_addr_i = paddr_i;
              
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

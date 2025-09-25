// APB Master

// TB should drive a cmd_i input decoded as:
//  - 2'b00 - No-op
//  - 2'b01 - Read from address 0xDEAD_CAFE
//  - 2'b10 - Increment the previously read data and store it to 0xDEAD_CAFE

module apb_master_interface (
  input       wire        clk,
  input       wire        reset,

  input       wire[1:0]   cmd_i,

  output      wire        psel_o,
  output      wire        penable_o,
  output      wire[31:0]  paddr_o,
  output      wire        pwrite_o,
  output      wire[31:0]  pwdata_o,
  input       wire        pready_i,
  input       wire[31:0]  prdata_i
);
  // Reading flag signal
  logic active_reading;

  // Saved data logic
  logic[31:0] saved_data;

  always_ff @(posedge clk) begin
    if (reset) begin
      saved_data <= 32'h00000000;
    end else begin
      if ((active_reading) && (penable_o) && (pready_i)) begin // It can safely get the read data from the transfer
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
  logic[31:0] addr;
  logic write;
  logic[31:0] wdata;

  // Reading flag logic
  always_ff @(posedge clk) begin
    if (reset) begin
      active_reading <= 1'b0;
    end else begin
      if ((cmd_i == 2'b01) && (cs == SETUP)) begin
        active_reading <= 1'b1;
      end else begin
        active_reading <= 1'b0;
      end
    end
  end

  // APB SM logic
  always_ff @(posedge clk) begin
    cs <= ns;
  end

  always_comb begin
    ns = IDLE;
    sel = 1'b0;
    enable = 1'b0;
    addr = 32'h00000000;
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
          addr = 32'hdeadcafe;

          if (cmd_i == 2'b10) begin // Write transfer 
            write = 1'b1;
            wdata = saved_data + 32'h00000001;
          end

          ns = ACCESS;
        end
        ACCESS: begin
          sel = 1'b1;
          enable = 1'b1;
          addr = 32'hdeadcafe;

          if (cmd_i == 2'b10) begin // Write transfer
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

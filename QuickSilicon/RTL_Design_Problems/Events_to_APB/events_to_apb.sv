// System that converts events to apb write transactions

module events_to_apb (
  input   logic         clk,
  input   logic         reset,

  input   logic         event_a_i,
  input   logic         event_b_i,
  input   logic         event_c_i,

  output  logic         apb_psel_o,
  output  logic         apb_penable_o,
  output  logic [31:0]  apb_paddr_o,
  output  logic         apb_pwrite_o,
  output  logic [31:0]  apb_pwdata_o,
  input   logic         apb_pready_i

);
  
  // Logic for the state register
  typedef enum logic[1:0] {IDLE, SETUP, ACCESS, ERR='X} state_t;
  state_t cs;
  state_t ns;

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      cs <= IDLE;
    else
      cs <= ns;
  end

  // Logic for the transaction signals shift registers used for timed outputs
  logic a_transaction;
  logic b_transaction;
  logic c_transaction;

  logic a_transaction_q;
  logic b_transaction_q;
  logic c_transaction_q;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      a_transaction_q <= 1'b0;
      b_transaction_q <= 1'b0;
      c_transaction_q <= 1'b0;
    end else begin
      a_transaction_q <= a_transaction;
      b_transaction_q <= b_transaction;
      c_transaction_q <= c_transaction;
    end
  end

  // Logic for the pending transactions registers
  logic a_pending;
  logic b_pending;
  logic c_pending;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      a_pending <= 1'b0;
      b_pending <= 1'b0;
      c_pending <= 1'b0;
    end else if ((cs == SETUP) || (cs == ACCESS)) begin
      if (event_a_i) begin
        a_pending <= 1'b1;
      end else if (event_b_i) begin
        b_pending <= 1'b1;
      end else if (event_c_i) begin
        c_pending <= 1'b1;
      end
    end else if (cs == IDLE) begin
      if (a_transaction) begin
        a_pending <= 1'b0;
      end else if (b_transaction) begin
        b_pending <= 1'b0;
      end else if (c_transaction) begin
        c_pending <= 1'b0;
      end
    end
  end

  // Logic for the counters of each event
  logic [31:0] a_events;
  logic [31:0] b_events;
  logic [31:0] c_events;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      a_events <= 32'h0;
      b_events <= 32'h0;
      c_events <= 32'h0;
    end else if (a_transaction) begin
      a_events <= 32'h0;
    end else if (b_transaction) begin
      b_events <= 32'h0;
    end else if (c_transaction) begin
      c_events <= 32'h0;
    end else if (event_a_i) begin
      a_events <= a_events + 32'h1;
    end else if (event_b_i) begin
      b_events <= b_events + 32'h1;
    end else if (event_c_i) begin
      c_events <= c_events + 32'h1;
    end
  end

  // Logic for the pending events registers
  logic [31:0] a_pending_events;
  logic [31:0] b_pending_events;
  logic [31:0] c_pending_events;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      a_pending_events <= 32'h0;
      b_pending_events <= 32'h0;
      c_pending_events <= 32'h0;
    end else if (a_transaction & event_a_i) begin
      a_pending_events <= a_events + 32'h1;
    end else if (b_transaction & event_b_i) begin
      b_pending_events <= b_events + 32'h1;
    end else if (c_transaction & event_c_i) begin
      c_pending_events <= c_events + 32'h1;
    end else if (a_transaction) begin
      a_pending_events <= a_events;
    end else if (b_transaction) begin
      b_pending_events <= b_events;
    end else if (c_transaction) begin
      c_pending_events <= c_events;
    end 
  end

  // Logic used for the write data output
  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      apb_pwdata_o <= 32'h0;
    else if (cs == SETUP) begin
      if (a_transaction_q)
        apb_pwdata_o <= a_pending_events;
      else if (b_transaction_q)
        apb_pwdata_o <= b_pending_events;
      else if (c_transaction_q)
        apb_pwdata_o <= c_pending_events;
    end
  end

  // Logic used for the address register
  logic [31:0] address;

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      address <= 32'h0;
    else if (a_transaction)
      address <= 32'habba0000;
    else if (b_transaction)
      address <= 32'hbaff0000;
    else if (c_transaction)
      address <= 32'hcafe0000;
  end

  always_comb begin
    if (cs == ACCESS)
      apb_paddr_o = address;
    else
      apb_paddr_o = 32'h0;
  end
  
  // Logic for the next state and the outputs from the SM that implement the APB transaction
  always_comb begin
    ns = IDLE;

    a_transaction = 1'b0;
    b_transaction = 1'b0;
    c_transaction = 1'b0;
    
    apb_psel_o = 1'b0;
    apb_penable_o = 1'b0;
    apb_pwrite_o = 1'b0;

    if (reset) begin
      ns = IDLE;
    end else begin
      case(cs)
        IDLE: begin
          if (event_a_i) begin
            ns = SETUP;
            a_transaction = 1'b1;
          end else if (event_b_i) begin
            ns = SETUP;
            b_transaction = 1'b1;
          end else if (event_c_i) begin
            ns = SETUP;
            c_transaction = 1'b1;
          end else if (a_pending) begin
            ns = SETUP;
            a_transaction = 1'b1;
          end else if (b_pending) begin
            ns = SETUP;
            b_transaction = 1'b1;
          end else if (c_pending) begin
            ns = SETUP;
            c_transaction = 1'b1;
          end
        end
        SETUP: begin
          ns = ACCESS;
          apb_psel_o = 1'b1;
        end
        ACCESS: begin
          if (apb_pready_i) begin
            ns = IDLE;
          end else begin
            ns = ACCESS;
          end

          apb_psel_o = 1'b1;
          apb_penable_o = 1'b1;
          apb_pwrite_o = 1'b1;
        end
        default: begin
          ns = IDLE;
        end
      endcase
    end
  end

endmodule

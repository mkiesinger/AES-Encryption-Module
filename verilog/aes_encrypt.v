module aes_encrypt(key_i, plain_i, in_ready_o, in_valid_i, cipher_o, out_ready_i, out_valid_o, clk, rst);

  input [127:0] key_i;
  input [127:0] plain_i;
  output in_ready_o;
  input in_valid_i;
  output [127:0] cipher_o;
  input out_ready_i;
  output out_valid_o;
  input clk;
  input rst;

  localparam [2:0] IDLE = 3'd0, KEY_W3 = 3'd1, STATE_W0 = 3'd2, STATE_W1 = 3'd3, STATE_W2 = 3'd4, STATE_W3 = 3'd5, DONE = 3'd6;

  // regs
  reg [2:0] fsm_state;
  reg [3:0] round;
  reg [127:0] aes_state, aes_key, out_buffer;
  reg out_buffer_full;

  // wires
  // next signals for internal registers
  reg [2:0] next_fsm_state;
  reg [3:0] next_round;
  reg [127:0] next_aes_state, next_aes_key, next_out_buffer;
  reg next_out_buffer_full;

  // internal wiring
  reg [31:0] subword_in;
  wire [31:0] subword_out;
  reg [127:0] shiftrows_in;
  wire [127:0] shiftrows_out;
  wire [31:0] mixcolumn_out;
  wire [127:0] expandkey_out;

  // helpers
  wire firstround, lastround;
  wire leaving_done_state;
  reg in_ready_s;
  wire outbuf_available;
  wire [31:0] pipe_out;

  // submodules
  subword subword_inst(.word_in(subword_in), .word_out(subword_out), .clk(clk));
  shiftrows shiftrows_inst(.state_in(shiftrows_in), .state_out(shiftrows_out));
  mixcolumn mixcolumn_inst(.column_in(subword_out), .column_out(mixcolumn_out));
  expandkey expandkey_inst(.round_in(round), .prev_key_in(aes_key), .next_key_out(expandkey_out), .subword_in(subword_out));

  always @(posedge clk) begin
    if (rst) begin
      fsm_state <= IDLE;
      round <= 4'h1;
      aes_state <= 128'h00000000_00000000_00000000_00000000;
      aes_key <= 128'h00000000_00000000_00000000_00000000;
      out_buffer <= 128'h00000000_00000000_00000000_00000000;
      out_buffer_full <= 1'b0;
    end
    else begin
      fsm_state <= next_fsm_state;
      round <= next_round;
      aes_state <= next_aes_state;
      aes_key <= next_aes_key;
      out_buffer <= next_out_buffer;
      out_buffer_full <= next_out_buffer_full;
    end
  end

  always @(*) begin
    next_fsm_state = fsm_state;
    next_round = round;
    next_aes_state = aes_state;
    next_aes_key = aes_key;
    next_out_buffer = out_buffer;
    next_out_buffer_full = out_buffer_full;

    subword_in = aes_key[127:96];
    in_ready_s = 1'b0;
    shiftrows_in = {mixcolumn_out ^ aes_key[127:96], aes_state[95:0]};

    case(fsm_state)
      IDLE: begin
        in_ready_s = 1'b1;
        if (in_valid_i) begin
          next_fsm_state = KEY_W3;
        end
      end
      KEY_W3: begin
        if (firstround) begin
          shiftrows_in = aes_state;
        end
        next_aes_state = shiftrows_out;
        next_fsm_state = STATE_W0;
      end
      STATE_W0: begin
        subword_in = aes_state[31:0];
        next_aes_key = expandkey_out;
        next_fsm_state = STATE_W1;
      end
      STATE_W1: begin
        subword_in = aes_state[63:32];
        next_aes_state[31:0] = pipe_out ^ aes_key[31:0];
        next_fsm_state = STATE_W2;
      end
      STATE_W2: begin
        subword_in = aes_state[95:64];
        next_aes_state[63:32] = pipe_out ^ aes_key[63:32];
        next_fsm_state = STATE_W3;
      end
      STATE_W3: begin
        subword_in = aes_state[127:96];
        if (!lastround) begin
          next_aes_state[95:64] = pipe_out ^ aes_key[95:64];
          next_round = round + 4'h1;
          next_fsm_state = KEY_W3;
        end
        else begin
          if (outbuf_available) begin
            in_ready_s = 1'b1;
            next_out_buffer = {aes_key[127:96], subword_out ^ aes_key[95:64], aes_state[63:0]};
          end
          else begin
            next_aes_state[95:64] = pipe_out ^ aes_key[95:64];
          end
          next_fsm_state = DONE;
        end
      end
      DONE: begin
        if (firstround) begin
          shiftrows_in = aes_state;
          next_aes_state = shiftrows_out;
          next_fsm_state = STATE_W0;
          next_out_buffer[127:96] = out_buffer[127:96] ^ subword_out;
        end
        else if (!out_ready_i) begin
          subword_in = aes_state[127:96];
          next_fsm_state = DONE;
        end
        else begin
          in_ready_s = 1'b1;
          next_out_buffer = {subword_out ^ aes_key[127:96], aes_state[95:0]};
          next_fsm_state = in_valid_i ? KEY_W3 : IDLE;
        end
      end
    endcase
    
    if (in_ready_o && in_valid_i) begin
      next_aes_state = plain_i ^ key_i;
      next_aes_key = key_i;
      next_round = 4'h1;
    end

    if (leaving_done_state) begin
      next_out_buffer_full = 1'b1;
    end
    else if (out_ready_i && out_valid_o) begin
      next_out_buffer_full = 1'b0;
    end
  end

  // helper signals
  assign firstround = round == 4'd1;
  assign lastround = round == 4'd10;
  assign leaving_done_state = fsm_state == DONE && next_fsm_state != DONE;
  assign outbuf_available = !out_buffer_full || out_ready_i;
  assign pipe_out = lastround ? subword_out : mixcolumn_out;

  // assign outputs
  assign cipher_o = out_buffer;
  assign out_valid_o = out_buffer_full;
  assign in_ready_o = in_ready_s;

endmodule

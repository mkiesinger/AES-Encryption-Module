module expandkey(round_in, prev_key_in, next_key_out, subword_in);

  input [3:0] round_in;
  input [127:0] prev_key_in; 
  input [31:0] subword_in;
  output [127:0] next_key_out;

  localparam [127:0] ROUNDCONST_PREFIX = 128'h00000000_00361b80_40201008_04020100;

  wire [31:0] rotsubword;
  wire [31:0] next_key_tmp [0:3];

  assign rotsubword = {subword_in[7:0], subword_in[31:8]};
  
  assign next_key_tmp[0] = rotsubword ^ prev_key_in[31:0] ^ {24'h000000, ROUNDCONST_PREFIX[round_in*8+:8]};
  assign next_key_tmp[1] = next_key_tmp[0] ^ prev_key_in[63:32];
  assign next_key_tmp[2] = next_key_tmp[1] ^ prev_key_in[95:64];
  assign next_key_tmp[3] = next_key_tmp[2] ^ prev_key_in[127:96];

  assign next_key_out = {next_key_tmp[3], next_key_tmp[2], next_key_tmp[1], next_key_tmp[0]};

endmodule



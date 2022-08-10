module subword(word_in, word_out, clk);

  input [31:0] word_in;
  output [31:0] word_out;
  input clk;

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin : subword_sboxes
      sbox sbox_inst (.byte_in(word_in[i*8+:8]), .byte_out(word_out[i*8+:8]), .clk(clk));
    end
  endgenerate

endmodule



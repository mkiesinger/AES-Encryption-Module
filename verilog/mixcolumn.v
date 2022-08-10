module mixcolumn(column_in, column_out);

  input [31:0] column_in;
  output [31:0] column_out;

  function automatic [7:0] mult;
    input [1:0] x;
    input [7:0] y;
    reg [7:0] t1;
    reg [7:0] t2;
    reg [7:0] xtime;
    begin
      xtime = y[7] ? {y[6:0], 1'b0} ^ 8'h1b : {y[6:0], 1'b0};
      t1 = x[0] ? y : 8'h00;
      t2 = x[1] ? xtime : 8'h00;
      mult = t1 ^ t2;
    end
  endfunction

  function automatic [31:0] mixcol_single_encrypt;
    input [31:0] vec;
    reg [7:0] b0, b1, b2, b3;
    reg [7:0] c0, c1, c2, c3;
    begin
      b0 = vec[7:0];
      b1 = vec[15:8];
      b2 = vec[23:16];
      b3 = vec[31:24];

      c0 = mult(2'b10, b0) ^ mult(2'b11, b1) ^ b2 ^ b3;
      c1 = b0 ^ mult(2'b10, b1) ^ mult(2'b11, b2) ^ b3;
      c2 = b0 ^ b1 ^ mult(2'b10, b2) ^ mult(2'b11, b3);
      c3 = mult(2'b11, b0) ^ b1 ^ b2 ^ mult(2'b10, b3);

      mixcol_single_encrypt = {c3, c2, c1, c0};
    end
  endfunction

  assign column_out = mixcol_single_encrypt(column_in);

endmodule



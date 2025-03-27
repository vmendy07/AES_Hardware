`timescale 1ns / 1ps

module mixcolumns #(
    parameter NB   = 4,      // Number of columns (matrix is NB x NB)
    parameter WORD = 8       // Size of each byte in bits
)(
    input  wire [NB*NB*WORD-1:0] i_block,  // 128-bit input state
    input  wire                  i_valid,
    output logic [NB*NB*WORD-1:0] o_block,  // 128-bit output state
    output logic                  o_valid
);

  // Function: Multiply by 2 in GF(2^8)
  function automatic [WORD-1:0] xtime;
    input [WORD-1:0] b;
    begin
      xtime = (b[7]) ? ((b << 1) ^ 8'h1B) : (b << 1);
    end
  endfunction

  // Extract each column's bytes (state is in column‑major order)
  // Column 0:
  wire [WORD-1:0] a0_0 = i_block[127:120];
  wire [WORD-1:0] a1_0 = i_block[119:112];
  wire [WORD-1:0] a2_0 = i_block[111:104];
  wire [WORD-1:0] a3_0 = i_block[103:96];

  // Column 1:
  wire [WORD-1:0] a0_1 = i_block[95:88];
  wire [WORD-1:0] a1_1 = i_block[87:80];
  wire [WORD-1:0] a2_1 = i_block[79:72];
  wire [WORD-1:0] a3_1 = i_block[71:64];

  // Column 2:
  wire [WORD-1:0] a0_2 = i_block[63:56];
  wire [WORD-1:0] a1_2 = i_block[55:48];
  wire [WORD-1:0] a2_2 = i_block[47:40];
  wire [WORD-1:0] a3_2 = i_block[39:32];

  // Column 3:
  wire [WORD-1:0] a0_3 = i_block[31:24];
  wire [WORD-1:0] a1_3 = i_block[23:16];
  wire [WORD-1:0] a2_3 = i_block[15:8];
  wire [WORD-1:0] a3_3 = i_block[7:0];

  // Compute MixColumns operation for each column.
  // For encryption:
  // r0 = xtime(a0) ⊕ (xtime(a1) ⊕ a1) ⊕ a2 ⊕ a3
  // r1 = a0 ⊕ xtime(a1) ⊕ (xtime(a2) ⊕ a2) ⊕ a3
  // r2 = a0 ⊕ a1 ⊕ xtime(a2) ⊕ (xtime(a3) ⊕ a3)
  // r3 = (xtime(a0) ⊕ a0) ⊕ a1 ⊕ a2 ⊕ xtime(a3)

  // Column 0:
  wire [WORD-1:0] r0_0 = xtime(a0_0) ^ (xtime(a1_0) ^ a1_0) ^ a2_0 ^ a3_0;
  wire [WORD-1:0] r1_0 = a0_0 ^ xtime(a1_0) ^ (xtime(a2_0) ^ a2_0) ^ a3_0;
  wire [WORD-1:0] r2_0 = a0_0 ^ a1_0 ^ xtime(a2_0) ^ (xtime(a3_0) ^ a3_0);
  wire [WORD-1:0] r3_0 = (xtime(a0_0) ^ a0_0) ^ a1_0 ^ a2_0 ^ xtime(a3_0);

  // Column 1:
  wire [WORD-1:0] r0_1 = xtime(a0_1) ^ (xtime(a1_1) ^ a1_1) ^ a2_1 ^ a3_1;
  wire [WORD-1:0] r1_1 = a0_1 ^ xtime(a1_1) ^ (xtime(a2_1) ^ a2_1) ^ a3_1;
  wire [WORD-1:0] r2_1 = a0_1 ^ a1_1 ^ xtime(a2_1) ^ (xtime(a3_1) ^ a3_1);
  wire [WORD-1:0] r3_1 = (xtime(a0_1) ^ a0_1) ^ a1_1 ^ a2_1 ^ xtime(a3_1);

  // Column 2:
  wire [WORD-1:0] r0_2 = xtime(a0_2) ^ (xtime(a1_2) ^ a1_2) ^ a2_2 ^ a3_2;
  wire [WORD-1:0] r1_2 = a0_2 ^ xtime(a1_2) ^ (xtime(a2_2) ^ a2_2) ^ a3_2;
  wire [WORD-1:0] r2_2 = a0_2 ^ a1_2 ^ xtime(a2_2) ^ (xtime(a3_2) ^ a3_2);
  wire [WORD-1:0] r3_2 = (xtime(a0_2) ^ a0_2) ^ a1_2 ^ a2_2 ^ xtime(a3_2);

  // Column 3:
  wire [WORD-1:0] r0_3 = xtime(a0_3) ^ (xtime(a1_3) ^ a1_3) ^ a2_3 ^ a3_3;
  wire [WORD-1:0] r1_3 = a0_3 ^ xtime(a1_3) ^ (xtime(a2_3) ^ a2_3) ^ a3_3;
  wire [WORD-1:0] r2_3 = a0_3 ^ a1_3 ^ xtime(a2_3) ^ (xtime(a3_3) ^ a3_3);
  wire [WORD-1:0] r3_3 = (xtime(a0_3) ^ a0_3) ^ a1_3 ^ a2_3 ^ xtime(a3_3);

  // Combine the computed columns into a 128-bit result.
  assign o_block = { r0_0, r1_0, r2_0, r3_0,
                     r0_1, r1_1, r2_1, r3_1,
                     r0_2, r1_2, r2_2, r3_2,
                     r0_3, r1_3, r2_3, r3_3 };

  // Pass the valid signal through.
  assign o_valid = i_valid;

endmodule 
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Organisation: University of Sheffield
// Engineer: EBranners
// 
// Date Created: 18.03.2025 19:31:16
// Design Title: AES Inverse MixColumns
// Module Name: aes_inv_mix_columns
// Project: AES Implementation
// Target Devices: FPGA 
// Tool Version: Xilinx Vivado 2021.2
// Description: 
//   This module performs the Inverse MixColumns transformation used in the AES 
//   decryption process. It operates on a 128-bit input state (4x4 byte matrix)
//   and applies the inverse MixColumns matrix multiplication in GF(2^8).
//
//   The transformation is applied column-wise to restore the state after
//   an encryption MixColumns operation.
//
// Revision History:
//   Rev 0.1 - Initial implementation
//   Rev 0.2 - Refactored to operate on full 128-bit state
//   Rev 0.3 - Added full GF(2^8) logic for inverse matrix multiplication
// Additional Notes:
//   Complies with AES standard FIPS-197.
//   The implementation assumes standard Rijndael finite field arithmetic.
//////////////////////////////////////////////////////////////////////////////////

module inv_mixcolumns #(
    parameter NB   = 4,      // Number of columns (matrix is NB x NB)
    parameter WORD = 8       // Size of each byte in bits
)(
    input  wire [NB*NB*WORD-1:0] i_block,  // 128-bit input state
    input  wire                  i_valid,
    output logic [NB*NB*WORD-1:0] o_block,  // 128-bit output state
    output logic                  o_valid
);

  // Function: Multiply in GF(2^8) by 2
  function automatic [WORD-1:0] xtime;
    input [WORD-1:0] b;
    begin
      xtime = (b[7]) ? ((b << 1) ^ 8'h1B) : (b << 1);
    end
  endfunction

  // Function: Multiply by 9 in GF(2^8)
  function automatic [WORD-1:0] mul9;
    input [WORD-1:0] b;
    begin
      mul9 = xtime(xtime(xtime(b))) ^ b;
    end
  endfunction

  // Function: Multiply by 11 in GF(2^8)
  function automatic [WORD-1:0] mul11;
    input [WORD-1:0] b;
    begin
      mul11 = xtime(xtime(xtime(b))) ^ xtime(b) ^ b;
    end
  endfunction

  // Function: Multiply by 13 in GF(2^8)
  function automatic [WORD-1:0] mul13;
    input [WORD-1:0] b;
    begin
      mul13 = xtime(xtime(xtime(b))) ^ xtime(xtime(b)) ^ b;
    end
  endfunction

  // Function: Multiply by 14 in GF(2^8)
  function automatic [WORD-1:0] mul14;
    input [WORD-1:0] b;
    begin
      mul14 = xtime(xtime(xtime(b))) ^ xtime(xtime(b)) ^ xtime(b);
    end
  endfunction

  // Extract each column's bytes
  wire [WORD-1:0] a0_0 = i_block[127:120];
  wire [WORD-1:0] a1_0 = i_block[119:112];
  wire [WORD-1:0] a2_0 = i_block[111:104];
  wire [WORD-1:0] a3_0 = i_block[103:96];

  wire [WORD-1:0] a0_1 = i_block[95:88];
  wire [WORD-1:0] a1_1 = i_block[87:80];
  wire [WORD-1:0] a2_1 = i_block[79:72];
  wire [WORD-1:0] a3_1 = i_block[71:64];

  wire [WORD-1:0] a0_2 = i_block[63:56];
  wire [WORD-1:0] a1_2 = i_block[55:48];
  wire [WORD-1:0] a2_2 = i_block[47:40];
  wire [WORD-1:0] a3_2 = i_block[39:32];

  wire [WORD-1:0] a0_3 = i_block[31:24];
  wire [WORD-1:0] a1_3 = i_block[23:16];
  wire [WORD-1:0] a2_3 = i_block[15:8];
  wire [WORD-1:0] a3_3 = i_block[7:0];

  // Compute InvMixColumns transformation
  wire [WORD-1:0] r0_0 = mul14(a0_0) ^ mul11(a1_0) ^ mul13(a2_0) ^ mul9(a3_0);
  wire [WORD-1:0] r1_0 = mul9(a0_0)  ^ mul14(a1_0) ^ mul11(a2_0) ^ mul13(a3_0);
  wire [WORD-1:0] r2_0 = mul13(a0_0) ^ mul9(a1_0)  ^ mul14(a2_0) ^ mul11(a3_0);
  wire [WORD-1:0] r3_0 = mul11(a0_0) ^ mul13(a1_0) ^ mul9(a2_0)  ^ mul14(a3_0);

  wire [WORD-1:0] r0_1 = mul14(a0_1) ^ mul11(a1_1) ^ mul13(a2_1) ^ mul9(a3_1);
  wire [WORD-1:0] r1_1 = mul9(a0_1)  ^ mul14(a1_1) ^ mul11(a2_1) ^ mul13(a3_1);
  wire [WORD-1:0] r2_1 = mul13(a0_1) ^ mul9(a1_1)  ^ mul14(a2_1) ^ mul11(a3_1);
  wire [WORD-1:0] r3_1 = mul11(a0_1) ^ mul13(a1_1) ^ mul9(a2_1)  ^ mul14(a3_1);

  wire [WORD-1:0] r0_2 = mul14(a0_2) ^ mul11(a1_2) ^ mul13(a2_2) ^ mul9(a3_2);
  wire [WORD-1:0] r1_2 = mul9(a0_2)  ^ mul14(a1_2) ^ mul11(a2_2) ^ mul13(a3_2);
  wire [WORD-1:0] r2_2 = mul13(a0_2) ^ mul9(a1_2)  ^ mul14(a2_2) ^ mul11(a3_2);
  wire [WORD-1:0] r3_2 = mul11(a0_2) ^ mul13(a1_2) ^ mul9(a2_2)  ^ mul14(a3_2);

  wire [WORD-1:0] r0_3 = mul14(a0_3) ^ mul11(a1_3) ^ mul13(a2_3) ^ mul9(a3_3);
  wire [WORD-1:0] r1_3 = mul9(a0_3)  ^ mul14(a1_3) ^ mul11(a2_3) ^ mul13(a3_3);
  wire [WORD-1:0] r2_3 = mul13(a0_3) ^ mul9(a1_3)  ^ mul14(a2_3) ^ mul11(a3_3);
  wire [WORD-1:0] r3_3 = mul11(a0_3) ^ mul13(a1_3) ^ mul9(a2_3)  ^ mul14(a3_3);

  // Combine output
  assign o_block = { r0_0, r1_0, r2_0, r3_0,
                     r0_1, r1_1, r2_1, r3_1,
                     r0_2, r1_2, r2_2, r3_2,
                     r0_3, r1_3, r2_3, r3_3 };

  // Pass the valid signal
  assign o_valid = i_valid;

endmodule

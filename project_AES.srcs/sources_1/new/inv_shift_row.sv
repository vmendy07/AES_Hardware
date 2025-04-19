`timescale 1ns / 1ps
// Organisation: University of Sheffield
// Engineer: EBranners
// 
// Date Created: 18.01.2025 17:41:16
// Design Title: AES Inverse ShiftRows
// Module Name: inv_shift_rows
// Project: AES Implementation
// Target Devices: FPGA 
// Tool Version: Xilinx Vivado 2021.2
// Description: 
//   This module implements the Inverse ShiftRows transformation 
//   used during the AES decryption process. It performs a cyclic 
//   right shift of each row in the AES 4x4 state matrix (except the first),
//   reversing the row-wise permutations applied during encryption.
//   The input and output are both 128-bit vectors representing the state
//   in column-major order.
//
// Revision History:
//   Rev 0.1 - Initial implementation
//   Rev 0.2 - Improved modularity and clarity
//
// Additional Notes:
//   The state matrix is internally interpreted as 16 bytes (4x4), and
//   the operation is purely combinational.


module inv_shiftrows #(
    parameter NB   = 4,      // Number of columns (matrix is NB x NB)
    parameter WORD = 8       // Size of each byte in bits
)(
    input  logic               i_valid,
    input  logic [NB*NB*WORD-1:0] i_block,  // 128-bit input state
    output logic               o_valid,
    output logic [NB*NB*WORD-1:0] o_block   // 128-bit output state
);

    // Extract 16 bytes from the 128-bit input
    wire [WORD-1:0] b0  = i_block[127:120];
    wire [WORD-1:0] b1  = i_block[119:112];
    wire [WORD-1:0] b2  = i_block[111:104];
    wire [WORD-1:0] b3  = i_block[103:96];
    wire [WORD-1:0] b4  = i_block[95:88];
    wire [WORD-1:0] b5  = i_block[87:80];
    wire [WORD-1:0] b6  = i_block[79:72];
    wire [WORD-1:0] b7  = i_block[71:64];
    wire [WORD-1:0] b8  = i_block[63:56];
    wire [WORD-1:0] b9  = i_block[55:48];
    wire [WORD-1:0] b10 = i_block[47:40];
    wire [WORD-1:0] b11 = i_block[39:32];
    wire [WORD-1:0] b12 = i_block[31:24];
    wire [WORD-1:0] b13 = i_block[23:16];
    wire [WORD-1:0] b14 = i_block[15:8];
    wire [WORD-1:0] b15 = i_block[7:0];

    // Apply the inverse ShiftRows transformation.
    // For each row r, the new value is S'[r][c] = S[r][(c - r) mod 4].
    // Re-flattened into column-major order, we get:
    // Column 0: S'[0,0]=b0,  S'[1,0]=b13, S'[2,0]=b10, S'[3,0]=b7
    // Column 1: S'[0,1]=b4,  S'[1,1]=b1,  S'[2,1]=b14, S'[3,1]=b11
    // Column 2: S'[0,2]=b8,  S'[1,2]=b5,  S'[2,2]=b2,  S'[3,2]=b15
    // Column 3: S'[0,3]=b12, S'[1,3]=b9,  S'[2,3]=b6,  S'[3,3]=b3

    assign o_block = { b0,  b13, b10, b7,    // Column 0
                       b4,  b1,  b14, b11,   // Column 1
                       b8,  b5,  b2,  b15,   // Column 2
                       b12, b9,  b6,  b3 };  // Column 3

    // Output valid signal is directly tied to input valid
    assign o_valid = i_valid;

endmodule

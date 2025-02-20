//////////////////////////////////////////////////////////////////////////////////
// Organisation: University of Sheffield
// Engineer: Vincent Mendy
// Date Created: 18.01.2025 17:41:16
// Design Title: AES AddRoundKey Module
// Module Name: add_roundkey
// Project: AES Implementation
// Target Devices: FPGA 
// Tool Version: Xilinx Vivado 2021.2
// Description: 
//   This module implements the AddRoundKey operation of the AES cipher.
//   It computes a bitwise XOR between a 128-bit data state and a 128-bit round key,
//   which is a critical step in every AES round.
// Dependencies: None (implements a combinational XOR operation)
// Revision History:
//   Rev 0.1: Initial implementation of the AddRoundKey module.
//////////////////////////////////////////////////////////////////////////////////

module add_roundkey (
    input  logic [127:0] state,      // 128-bit input representing the current AES state.
    input  logic [127:0] round_key,  // 128-bit round key used to modify the state.
    output logic [127:0] state_out   // 128-bit output after performing the bitwise XOR.
);

  // Compute the AddRoundKey operation by XORing the input state with the round key.
  // This is a simple combinational logic function.
  assign state_out = state ^ round_key;

endmodule 
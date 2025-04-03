`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2025 12:28:50
// Design Name: 
// Module Name: add_Round
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module add_roundkey #(
    parameter NB   = 4,      // Number of columns (matrix is NB x NB)
    parameter WORD = 8       // Size of each byte in bits
)(
    input  logic               i_valid,    // Input valid signal
    input  logic [NB*NB*WORD-1:0] state,     // 128-bit input state
    input  logic [NB*NB*WORD-1:0] round_key, // 128-bit round key
    output logic               o_valid,    // Output valid signal
    output logic [NB*NB*WORD-1:0] state_out  // 128-bit output state
);

    // Perform the AddRoundKey operation (bitwise XOR)
    assign state_out = state ^ round_key;

    // Directly propagate the valid signal
    assign o_valid = i_valid;

endmodule


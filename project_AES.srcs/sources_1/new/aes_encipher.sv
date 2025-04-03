`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Sheffield  
// Engineer: E. Branners  
//  
// Create Date  : 13/02/2025 14:32:53  
// Design Name  : AES Core Module  
// Module Name  : aes_core  
// Project Name : AES Encryption/Decryption System  
// Target Device: FPGA (Artix-7, Nexys4 DDR)  
// Tool Version : Xilinx Vivado 2021.2  
//  
// Description:  
// This module implements the AES encryption and decryption core using a pipelined  
// architecture for improved throughput. The design supports AES-128 encryption  
// and consists of modular components, including key expansion, round transformations,  
// and AddRoundKey operations. A dedicated key expansion module precomputes the  
// round keys, enabling efficient processing of multiple blocks.  
//  
// Dependencies:  
// - key_expansion.v (AES key schedule implementation)  
// - aes_round.v (Round transformation logic)  
// - add_round_key.v (Initial and final round key addition)  
//  
// Revision History:  
// - Rev 0.01 (13/02/2025): Initial creation  
// - Rev 0.02 (TBD)       : Further optimizations and pipeline enhancements  
//  
// Additional Comments:  
// - Designed for high-throughput encryption by leveraging pipelining.  
// - Ensures modularity for ease of debugging and future scalability.  
//  
//////////////////////////////////////////////////////////////////////////////////


module AES_Cipher_Round (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);

    wire [127:0] sub_bytes_out;
    wire [127:0] shift_rows_out;
    wire [127:0] mix_columns_out;

    // SubBytes stage
    SubBytes sub_bytes_inst (
        .state_in(state_in),
        .state_out(sub_bytes_out)
    );

    // ShiftRows stage
    ShiftRows shift_rows_inst (
        .state_in(sub_bytes_out),
        .state_out(shift_rows_out)
    );

    // MixColumns stage
    MixColumns mix_columns_inst (
        .state_in(shift_rows_out),
        .state_out(mix_columns_out)
    );

    // AddRoundKey stage
    assign state_out = mix_columns_out ^ round_key;

endmodule





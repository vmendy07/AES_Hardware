`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Sheffield
// Engineer: EBranners
// 
// Create Date: 18.02.2025 00:23:27
// Design Name: AES Top-Level Module
// Module Name: AES
// Project Name: AES Encryption/Decryption
// Target Devices: FPGA
// Tool Versions: Xilinx Vivado 2021.2
// Description: 
//     This module serves as the top-level wrapper for the AES encryption and
//     decryption functionality. It integrates the key expansion and AES core
//     modules to perform AES operations based on the control signals.
// Dependencies:
//     key_expansion - Key expansion module for generating round keys
//     aes_core - Core AES encryption/decryption module
// 
// Revision:
//     Revision 0.01 - File Created
// 
//////////////////////////////////////////////////////////////////////////////////

module AES (
    input clk,                     // Clock signal
    input reset,                   // Active-high reset signal
    input encode,                  // Control signal: 1 = encrypt, 0 = decrypt
    input [127:0] key,             // 128-bit AES encryption key
    input [127:0] input_data,      // 128-bit input data (plaintext or ciphertext)
    input KeyReady,                // Key ready handshake signal
    input InputDataReady,          // Input data ready handshake signal
    output reg [127:0] output_data, // 128-bit output data (ciphertext or plaintext)
    output reg OutputDataReady     // Output data ready handshake signal
);

    // Internal wires for round keys and cipher data
    wire [127:0] round_keys [0:10];  // Round keys for AES-128 (11 keys for 10 rounds)
    wire [127:0] cipher_data;        // 128-bit cipher data (result from AES core)
    wire round_complete;             // Signal indicating AES operation is complete

    // Key Expansion Module: Generates the round keys from the given AES key
    key_expansion key_expansion_inst (
        .clk(clk),
        .reset(reset),
        .key(key),
        .key_ready(KeyReady),
        .round_keys(round_keys)
    );

    // AES Core Module: Performs the AES encryption or decryption using round keys
    aes_core aes_core_inst (
        .clk(clk),
        .reset(reset),
        .encode(encode),
        .input_data(input_data),
        .round_keys(round_keys),
        .output_data(cipher_data),
        .round_complete(round_complete)
    );

    // Output and Handshake Management
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset output data and OutputDataReady signal
            output_data <= 128'b0;
            OutputDataReady <= 1'b0;
        end else begin
            // Manage the output and handshake once the AES round is complete
            if (round_complete) begin
                output_data <= cipher_data;
                OutputDataReady <= 1'b1;  // Indicate that output data is ready
            end else begin
                OutputDataReady <= 1'b0;  // No output data ready if round is not complete
            end
        end
    end

endmodule


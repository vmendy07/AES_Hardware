`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2025 18:05:40
// Design Name: 
// Module Name: aes_key_expansion
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Organisation: University of Sheffield
// Engineer: EBranners
// 
// Date Created: 18.01.2025 17:41:16
// Design Title: AES Key Expansion
// Module Name: aes_key_expansion
// Project: AES Implementation
// Target Devices: FPGA 
// Tool Version: Xilinx Vivado 2021.2
// Description: 
//   This module generates round keys required for AES encryption/decryption.
//   It derives the key schedule from an initial key and outputs an array of 
//   round keys (each 128 bits as hexadecimal values) rather than one huge flattened vector.
//
// Revision History:
//   Rev 0.2 - Improved modularity and commenting
//   Rev 0.3 - Updated key expansion to output a vector of round keys.
// Additional Notes:
//   The implementation supports variable key sizes via parameters.
//////////////////////////////////////////////////////////////////////////////////

module aes_key_expansion #(parameter KEY_WORDS = 4, parameter ROUNDS = 10)(
    input  [0:(KEY_WORDS*32)-1] seed_key, // Original AES key (e.g. 128 bits for AES-128)
    output reg [127:0] expanded_keys [0:ROUNDS] // Array of round keys; each element is 128 bits (round key)
);

// Internal registers for key expansion (we build the complete schedule as an array of 32-bit words)
reg [31:0] key_schedule [0:(4*(ROUNDS+1))-1];
reg [31:0] temp_word;      // Temporary word storage
reg [31:0] rotated;        // Stores the rotated key word
reg [31:0] substituted;    // Holds S-Box processed word
reg [31:0] round_const;    // Round constant for key expansion

integer i, j;  // Iteration indices

// Key expansion always block 
always @* begin
    // Initialize first KEY_WORDS (e.g. 4 for AES-128) words from seed_key.
    // The seed_key is assumed to be packed as 4 consecutive 32-bit words.
    for (i = 0; i < KEY_WORDS; i = i + 1) begin
        // Extract 32-bit slice (using the +: operator to get a 32-bit chunk)
        key_schedule[i] = seed_key[32*i +: 32];
    end

    // Generate the rest of the key schedule words
    for (j = KEY_WORDS; j < 4*(ROUNDS+1); j = j + 1) begin
        temp_word = key_schedule[j-1];
        // Perform the key schedule core every KEY_WORDS words
        if (j % KEY_WORDS == 0) begin
            rotated = rotate_word(temp_word);
            substituted = apply_sbox(rotated);
            round_const = round_constant(j / KEY_WORDS);
            key_schedule[j] = key_schedule[j - KEY_WORDS] ^ (substituted ^ round_const);
        end 
        // For keys larger than AES-128, extra S-Box processing is done for j mod KEY_WORDS == 4.
        else if (KEY_WORDS > 6 && (j % KEY_WORDS == 4)) begin
            key_schedule[j] = key_schedule[j - KEY_WORDS] ^ apply_sbox(temp_word);
        end 
        // Otherwise, the new word is the XOR of the corresponding word KEY_WORDS back and the previous word.
        else begin
            key_schedule[j] = key_schedule[j - KEY_WORDS] ^ temp_word;
        end
    end

    // Reassemble the key schedule words into an array of 128-bit round keys.
    // Each round key consists of 4 consecutive 32-bit words.
    for (i = 0; i <= ROUNDS; i = i + 1) begin
        expanded_keys[i] = { key_schedule[i*4],
                             key_schedule[i*4 + 1],
                             key_schedule[i*4 + 2],
                             key_schedule[i*4 + 3] };
    end
end

// Function: Cyclically shift a 32-bit word left by 8 bits (rotate bytes)
function [31:0] rotate_word;
    input [31:0] word_in;
    begin
        rotate_word = {word_in[23:0], word_in[31:24]};
    end
endfunction

// Function: Apply S-Box substitution to each byte of the word
function [31:0] apply_sbox;
    input [31:0] word;
    reg [7:0] b0, b1, b2, b3;
    begin
        // Split the 32-bit word into four 8-bit bytes
        b0 = word[31:24];
        b1 = word[23:16];
        b2 = word[15:8];
        b3 = word[7:0];
        // Substitute each byte using the sbox_lookup function
        apply_sbox = { sbox_lookup(b0),
                       sbox_lookup(b1),
                       sbox_lookup(b2),
                       sbox_lookup(b3) };
    end
endfunction

// Function: Round constant lookup function.
// Returns the appropriate round constant based on the round index.
function [31:0] round_constant;
    input integer round_index;
    begin
        case (round_index)
            1: round_constant = 32'h01000000;
            2: round_constant = 32'h02000000;
            3: round_constant = 32'h04000000;
            4: round_constant = 32'h08000000;
            5: round_constant = 32'h10000000;
            6: round_constant = 32'h20000000;
            7: round_constant = 32'h40000000;
            8: round_constant = 32'h80000000;
            9: round_constant = 32'h1b000000;
            10: round_constant = 32'h36000000;
            default: round_constant = 32'h00000000;
        endcase
    end
endfunction

// Function: AES S-Box lookup table for an 8-bit input.
function [7:0] sbox_lookup;
    input [7:0] byte_in;
    begin
        case (byte_in)
            8'h00: sbox_lookup = 8'h63;
            8'h01: sbox_lookup = 8'h7c;
            8'h02: sbox_lookup = 8'h77;
            8'h03: sbox_lookup = 8'h7b;
            8'h04: sbox_lookup = 8'hf2;
            8'h05: sbox_lookup = 8'h6b;
            8'h06: sbox_lookup = 8'h6f;
            8'h07: sbox_lookup = 8'hc5;
            8'h08: sbox_lookup = 8'h30;
            8'h09: sbox_lookup = 8'h01;
            8'h0a: sbox_lookup = 8'h67;
            8'h0b: sbox_lookup = 8'h2b;
            8'h0c: sbox_lookup = 8'hfe;
            8'h0d: sbox_lookup = 8'hd7;
            8'h0e: sbox_lookup = 8'hab;
            8'h0f: sbox_lookup = 8'h76;
            8'h10: sbox_lookup = 8'hca;
            8'h11: sbox_lookup = 8'h82;
            8'h12: sbox_lookup = 8'hc9;
            8'h13: sbox_lookup = 8'h7d;
            8'h14: sbox_lookup = 8'hfa;
            8'h15: sbox_lookup = 8'h59;
            8'h16: sbox_lookup = 8'h47;
            8'h17: sbox_lookup = 8'hf0;
            8'h18: sbox_lookup = 8'had;
            8'h19: sbox_lookup = 8'hd4;
            8'h1a: sbox_lookup = 8'ha2;
            8'h1b: sbox_lookup = 8'haf;
            8'h1c: sbox_lookup = 8'h9c;
            8'h1d: sbox_lookup = 8'ha4;
            8'h1e: sbox_lookup = 8'h72;
            8'h1f: sbox_lookup = 8'hc0;
            8'h20: sbox_lookup = 8'hb7;
            8'h21: sbox_lookup = 8'hfd;
            8'h22: sbox_lookup = 8'h93;
            8'h23: sbox_lookup = 8'h26;
            8'h24: sbox_lookup = 8'h36;
            8'h25: sbox_lookup = 8'h3f;
            8'h26: sbox_lookup = 8'hf7;
            8'h27: sbox_lookup = 8'hcc;
            8'h28: sbox_lookup = 8'h34;
            8'h29: sbox_lookup = 8'ha5;
            8'h2a: sbox_lookup = 8'he5;
            8'h2b: sbox_lookup = 8'hf1;
            8'h2c: sbox_lookup = 8'h71;
            8'h2d: sbox_lookup = 8'hd8;
            8'h2e: sbox_lookup = 8'h31;
            8'h2f: sbox_lookup = 8'h15;
            8'h30: sbox_lookup = 8'h04;
            8'h31: sbox_lookup = 8'hc7;
            8'h32: sbox_lookup = 8'h23;
            8'h33: sbox_lookup = 8'hc3;
            8'h34: sbox_lookup = 8'h18;
            8'h35: sbox_lookup = 8'h96;
            8'h36: sbox_lookup = 8'h05;
            8'h37: sbox_lookup = 8'h9a;
            8'h38: sbox_lookup = 8'h07;
            8'h39: sbox_lookup = 8'h12;
            8'h3a: sbox_lookup = 8'h80;
            8'h3b: sbox_lookup = 8'he2;
            8'h3c: sbox_lookup = 8'heb;
            8'h3d: sbox_lookup = 8'h27;
            8'h3e: sbox_lookup = 8'hb2;
            8'h3f: sbox_lookup = 8'h75;
            8'h40: sbox_lookup = 8'h09;
            8'h41: sbox_lookup = 8'h83;
            8'h42: sbox_lookup = 8'h2c;
            8'h43: sbox_lookup = 8'h1a;
            8'h44: sbox_lookup = 8'h1b;
            8'h45: sbox_lookup = 8'h6e;
            8'h46: sbox_lookup = 8'h5a;
            8'h47: sbox_lookup = 8'ha0;
            8'h48: sbox_lookup = 8'h52;
            8'h49: sbox_lookup = 8'h3b;
            8'h4a: sbox_lookup = 8'hd6;
            8'h4b: sbox_lookup = 8'hb3;
            8'h4c: sbox_lookup = 8'h29;
            8'h4d: sbox_lookup = 8'he3;
            8'h4e: sbox_lookup = 8'h2f;
            8'h4f: sbox_lookup = 8'h84;
            8'h50: sbox_lookup = 8'h53;
            8'h51: sbox_lookup = 8'hd1;
            8'h52: sbox_lookup = 8'h00;
            8'h53: sbox_lookup = 8'hed;
            8'h54: sbox_lookup = 8'h20;
            8'h55: sbox_lookup = 8'hfc;
            8'h56: sbox_lookup = 8'hb1;
            8'h57: sbox_lookup = 8'h5b;
            8'h58: sbox_lookup = 8'h6a;
            8'h59: sbox_lookup = 8'hcb;
            8'h5a: sbox_lookup = 8'hbe;
            8'h5b: sbox_lookup = 8'h39;
            8'h5c: sbox_lookup = 8'h4a;
            8'h5d: sbox_lookup = 8'h4c;
            8'h5e: sbox_lookup = 8'h58;
            8'h5f: sbox_lookup = 8'hcf;
            8'h60: sbox_lookup = 8'hd0;
            8'h61: sbox_lookup = 8'hef;
            8'h62: sbox_lookup = 8'haa;
            8'h63: sbox_lookup = 8'hfb;
            8'h64: sbox_lookup = 8'h43;
            8'h65: sbox_lookup = 8'h4d;
            8'h66: sbox_lookup = 8'h33;
            8'h67: sbox_lookup = 8'h85;
            8'h68: sbox_lookup = 8'h45;
            8'h69: sbox_lookup = 8'hf9;
            8'h6a: sbox_lookup = 8'h02;
            8'h6b: sbox_lookup = 8'h7f;
            8'h6c: sbox_lookup = 8'h50;
            8'h6d: sbox_lookup = 8'h3c;
            8'h6e: sbox_lookup = 8'h9f;
            8'h6f: sbox_lookup = 8'ha8;
            8'h70: sbox_lookup = 8'h51;
            8'h71: sbox_lookup = 8'ha3;
            8'h72: sbox_lookup = 8'h40;
            8'h73: sbox_lookup = 8'h8f;
            8'h74: sbox_lookup = 8'h92;
            8'h75: sbox_lookup = 8'h9d;
            8'h76: sbox_lookup = 8'h38;
            8'h77: sbox_lookup = 8'hf5;
            8'h78: sbox_lookup = 8'hbc;
            8'h79: sbox_lookup = 8'hb6;
            8'h7a: sbox_lookup = 8'hda;
            8'h7b: sbox_lookup = 8'h21;
            8'h7c: sbox_lookup = 8'h10;
            8'h7d: sbox_lookup = 8'hff;
            8'h7e: sbox_lookup = 8'hf3;
            8'h7f: sbox_lookup = 8'hd2;
            8'h80: sbox_lookup = 8'hcd;
            8'h81: sbox_lookup = 8'h0c;
            8'h82: sbox_lookup = 8'h13;
            8'h83: sbox_lookup = 8'hec;
            8'h84: sbox_lookup = 8'h5f;
            8'h85: sbox_lookup = 8'h97;
            8'h86: sbox_lookup = 8'h44;
            8'h87: sbox_lookup = 8'h17;
            8'h88: sbox_lookup = 8'hc4;
            8'h89: sbox_lookup = 8'ha7;
            8'h8a: sbox_lookup = 8'h7e;
            8'h8b: sbox_lookup = 8'h3d;
            8'h8c: sbox_lookup = 8'h64;
            8'h8d: sbox_lookup = 8'h5d;
            8'h8e: sbox_lookup = 8'h19;
            8'h8f: sbox_lookup = 8'h73;
            8'h90: sbox_lookup = 8'h60;
            8'h91: sbox_lookup = 8'h81;
            8'h92: sbox_lookup = 8'h4f;
            8'h93: sbox_lookup = 8'hdc;
            8'h94: sbox_lookup = 8'h22;
            8'h95: sbox_lookup = 8'h2a;
            8'h96: sbox_lookup = 8'h90;
            8'h97: sbox_lookup = 8'h88;
            8'h98: sbox_lookup = 8'h46;
            8'h99: sbox_lookup = 8'hee;
            8'h9a: sbox_lookup = 8'hb8;
            8'h9b: sbox_lookup = 8'h14;
            8'h9c: sbox_lookup = 8'hde;
            8'h9d: sbox_lookup = 8'h5e;
            8'h9e: sbox_lookup = 8'h0b;
            8'h9f: sbox_lookup = 8'hdb;
            8'ha0: sbox_lookup = 8'he0;
            8'ha1: sbox_lookup = 8'h32;
            8'ha2: sbox_lookup = 8'h3a;
            8'ha3: sbox_lookup = 8'h0a;
            8'ha4: sbox_lookup = 8'h49;
            8'ha5: sbox_lookup = 8'h06;
            8'ha6: sbox_lookup = 8'h24;
            8'ha7: sbox_lookup = 8'h5c;
            8'ha8: sbox_lookup = 8'hc2;
            8'ha9: sbox_lookup = 8'hd3;
            8'haa: sbox_lookup = 8'hac;
            8'hab: sbox_lookup = 8'h62;
            8'hac: sbox_lookup = 8'h91;
            8'had: sbox_lookup = 8'h95;
            8'hae: sbox_lookup = 8'he4;
            8'haf: sbox_lookup = 8'h79;
            8'hb0: sbox_lookup = 8'he7;
            8'hb1: sbox_lookup = 8'hc8;
            8'hb2: sbox_lookup = 8'h37;
            8'hb3: sbox_lookup = 8'h6d;
            8'hb4: sbox_lookup = 8'h8d;
            8'hb5: sbox_lookup = 8'hd5;
            8'hb6: sbox_lookup = 8'h4e;
            8'hb7: sbox_lookup = 8'ha9;
            8'hb8: sbox_lookup = 8'h6c;
            8'hb9: sbox_lookup = 8'h56;
            8'hba: sbox_lookup = 8'hf4;
            8'hbb: sbox_lookup = 8'hea;
            8'hbc: sbox_lookup = 8'h65;
            8'hbd: sbox_lookup = 8'h7a;
            8'hbe: sbox_lookup = 8'hae;
            8'hbf: sbox_lookup = 8'h08;
            8'hc0: sbox_lookup = 8'hba;
            8'hc1: sbox_lookup = 8'h78;
            8'hc2: sbox_lookup = 8'h25;
            8'hc3: sbox_lookup = 8'h2e;
            8'hc4: sbox_lookup = 8'h1c;
            8'hc5: sbox_lookup = 8'ha6;
            8'hc6: sbox_lookup = 8'hb4;
            8'hc7: sbox_lookup = 8'hc6;
            8'hc8: sbox_lookup = 8'he8;
            8'hc9: sbox_lookup = 8'hdd;
            8'hca: sbox_lookup = 8'h74;
            8'hcb: sbox_lookup = 8'h1f;
            8'hcc: sbox_lookup = 8'h4b;
            8'hcd: sbox_lookup = 8'hbd;
            8'hce: sbox_lookup = 8'h8b;
            8'hcf: sbox_lookup = 8'h8a;
            8'hd0: sbox_lookup = 8'h70;
            8'hd1: sbox_lookup = 8'h3e;
            8'hd2: sbox_lookup = 8'hb5;
            8'hd3: sbox_lookup = 8'h66;
            8'hd4: sbox_lookup = 8'h48;
            8'hd5: sbox_lookup = 8'h03;
            8'hd6: sbox_lookup = 8'hf6;
            8'hd7: sbox_lookup = 8'h0e;
            8'hd8: sbox_lookup = 8'h61;
            8'hd9: sbox_lookup = 8'h35;
            8'hda: sbox_lookup = 8'h57;
            8'hdb: sbox_lookup = 8'hb9;
            8'hdc: sbox_lookup = 8'h86;
            8'hdd: sbox_lookup = 8'hc1;
            8'hde: sbox_lookup = 8'h1d;
            8'hdf: sbox_lookup = 8'h9e;
            8'he0: sbox_lookup = 8'he1;
            8'he1: sbox_lookup = 8'hf8;
            8'he2: sbox_lookup = 8'h98;
            8'he3: sbox_lookup = 8'h11;
            8'he4: sbox_lookup = 8'h69;
            8'he5: sbox_lookup = 8'hd9;
            8'he6: sbox_lookup = 8'h8e;
            8'he7: sbox_lookup = 8'h94;
            8'he8: sbox_lookup = 8'h9b;
            8'he9: sbox_lookup = 8'h1e;
            8'hea: sbox_lookup = 8'h87;
            8'heb: sbox_lookup = 8'he9;
            8'hec: sbox_lookup = 8'hce;
            8'hed: sbox_lookup = 8'h55;
            8'hee: sbox_lookup = 8'h28;
            8'hef: sbox_lookup = 8'hdf;
            8'hf0: sbox_lookup = 8'h8c;
            8'hf1: sbox_lookup = 8'ha1;
            8'hf2: sbox_lookup = 8'h89;
            8'hf3: sbox_lookup = 8'h0d;
            8'hf4: sbox_lookup = 8'hbf;
            8'hf5: sbox_lookup = 8'he6;
            8'hf6: sbox_lookup = 8'h42;
            8'hf7: sbox_lookup = 8'h68;
            8'hf8: sbox_lookup = 8'h41;
            8'hf9: sbox_lookup = 8'h99;
            8'hfa: sbox_lookup = 8'h2d;
            8'hfb: sbox_lookup = 8'h0f;
            8'hfc: sbox_lookup = 8'hb0;
            8'hfd: sbox_lookup = 8'h54;
            8'hfe: sbox_lookup = 8'hbb;
            8'hff: sbox_lookup = 8'h16;
        endcase
    end
endfunction

endmodule
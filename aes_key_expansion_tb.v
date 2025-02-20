`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Sheffield
// Engineer: Ebranners
//
// Create Date: 20.01.2025 23:48:03
// Design Name: AES Key Schedule Testbench
// Module Name: aes_key_schedule_tb
// Project Name: AES Project
// Target Devices: FPGA
// Tool Versions: Xilinx Vivado 2021.2
// Description: Testbench for AES Key Schedule (formerly AES Key Expansion)
//
// Dependencies: aes_key_schedule module
//
// Revision:
// Revision 0.02 - Updated to match new module and variable names
// Additional Comments:
// - Updated variable names for clarity and uniqueness
// - Maintained full functionality while improving readability
//
//////////////////////////////////////////////////////////////////////////////////

module aes_key_schedule_tb;
    // Input 128-bit seed key for AES key scheduling (128-bit mode)
    reg [127:0] seed_key;
    
    // Output: Expanded key schedule (44 words * 32 bits = 1408 bits)
    wire [1407:0] expanded_keys;

    // Instantiate the AES key schedule module
    aes_key_schedule #(4, 10) key_schedule_instance (
        .seed_key(seed_key),
        .expanded_keys(expanded_keys)
    );

    // Task to display the expanded key words
    task display_expanded_key;
        integer i;
        begin
            $display("------------------------------------------------------");
            $display("Seed Key: %h", seed_key);
            $display("Generated Key Schedule:");
            
            // Loop through each of the 11 rounds and display the 4 words per round
            for (i = 0; i < 11; i = i + 1) begin
                $display("Round %2d:", i);  // Round number
                // Display 4 words (128 bits) per round
                $display("  expanded_keys[%0d]: %h %h %h %h", 
                    i, 
                    expanded_keys[(1407 - (i * 128)) -: 32], 
                    expanded_keys[(1375 - (i * 128)) -: 32], 
                    expanded_keys[(1343 - (i * 128)) -: 32], 
                    expanded_keys[(1311 - (i * 128)) -: 32]
                );
            end
            $display("------------------------------------------------------\n");
        end
    endtask

    // Test procedure
    initial begin
        // Test Case 1: Standard 128-bit AES key
        seed_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;  
        #10;  
        display_expanded_key;

        // Test Case 2: Another 128-bit AES key
        seed_key = 128'h00112233445566778899aabbccddeeff;  
        #10;  
        display_expanded_key;

        // Test Case 3: Edge case - all bits set to 0
        seed_key = 128'h0;  
        #10;  
        display_expanded_key;

        // Test Case 4: Edge case - all bits set to 1
        seed_key = 128'hffffffffffffffffffffffffffffffff;  
        #10;  
        display_expanded_key;

        // Test Case 5: Random 128-bit AES key
        seed_key = 128'h1a2b3c4d5e6f708192a2b3c4d5e6f708;  
        #10;  
        display_expanded_key;

        // Test Case 6: Another random key
        seed_key = 128'h1234567890abcdef1234567890abcdef;  
        #10;  
        display_expanded_key;

        $stop;  
    end
endmodule







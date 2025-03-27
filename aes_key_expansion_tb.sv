`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Organisation: University of Sheffield
// Engineer: EBranners
//
// Module Name: aes_key_expansion_tb
// Project Name: AES Project
// Target Devices: FPGA
// Tool Versions: Xilinx Vivado 2021.2
// Description: Testbench for AES Key expansion (formerly AES Key Expansion)
//
// Dependencies: aes_key_expansion module
//
// Revision:
// Revision 0.02 - Updated to match new module and variable names
// Additional Comments:
// - Updated variable names for clarity and uniqueness
// - Maintained full functionality while improving readability
//
//////////////////////////////////////////////////////////////////////////////////

module aes_key_expansion_tb;

    // 128-bit seed key for AES key scheduling (AES-128)
    reg [127:0] seed_key;

    // Output: Expanded keys as an array of 11 128-bit round keys
    // (For AES-128 there are 11 round keys, round 0 to round 10)
    logic [127:0] expanded_keys [0:10];

    // Instantiate the AES key expansion module with parameters KEY_WORDS=4 and ROUNDS=10
    aes_key_expansion #(4, 10) key_expansion_instance (
        .seed_key(seed_key),
        .expanded_keys(expanded_keys)
    );

    // Task to display the expanded round keys
    task display_expanded_key;
        integer i;
        begin
            $display("------------------------------------------------------");
            $display("Seed Key: %h", seed_key);
            $display("Generated Round Keys:");
            for (i = 0; i <= 10; i = i + 1) begin
                $display("Round %2d: %h", i, expanded_keys[i]);
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
        
        // Test Case 7: Another random key
        seed_key = 128'h000102030405060708090a0b0c0d0e0f;  
        #10;  
        display_expanded_key;

        $stop;
    end

endmodule

//13111d7fe3944a17f307a78b4d2b30c5
//13111d7fe3944a17f307a78b4d2b30c5




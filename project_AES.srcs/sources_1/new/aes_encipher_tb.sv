`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.03.2025 10:19:21
// Design Name: 
// Module Name: aes_encipher_tb
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


module tb_AES_Cipher_Round;

    // Testbench signals
    reg [127:0] state_in;     // Input state
    reg [127:0] round_key;    // Input round key
    wire [127:0] state_out;   // Output state after round

    // Instantiate the AES_Cipher_Round module
    AES_Cipher_Round uut (
        .state_in(state_in),
        .round_key(round_key),
        .state_out(state_out)
    );

    // Clock generation
    reg clk;
    always #5 clk = ~clk; // 10 ns clock period

    // Initialize the inputs
    initial begin
        clk = 0;
        state_in = 128'h3243f6a8885a308d313198a2e0370734;  // Example input state (128-bit)
        round_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;  // Example round key (128-bit)
    end

    // Apply test vectors and check outputs
    initial begin
        // Display headers for results
        $display("Time\tstate_in\t\t\t\t\tround_key\t\t\t\t\tstate_out");

        // Monitor signals
        $monitor("%g\t%h\t%h\t%h", $time, state_in, round_key, state_out);

        // Wait for a few clock cycles to observe behavior
        #10;

        // Test Case 1: Apply different state_in and round_key values
        state_in = 128'h00112233445566778899aabbccddeeff;
        round_key = 128'h0123456789abcdef0123456789abcdef;

        // Wait a few cycles for results
        #10;

        // Test Case 2: Another set of inputs
        state_in = 128'hdeadbeefcafebabe1234567890abcdef;
        round_key = 128'habcdefabcdefabcdefabcdefabcdef;

        // Wait a few cycles for results
        #10;

        // Test Case 3: Same input, but different round_key
        state_in = 128'h3243f6a8885a308d313198a2e0370734;
        round_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;

        // Wait a few cycles to check
        #10;

        // End simulation
        $finish;
    end

endmodule


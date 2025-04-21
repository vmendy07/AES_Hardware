`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.04.2025 01:48:06
// Design Name: 
// Module Name: decrypt_top_10_stream
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

module decrypt_top_10_stream;

    // Testbench signals
    reg clk;
    reg rst;
    reg [127:0] ciphertext;
    reg [127:0] key;
    wire [127:0] plaintext;

    // Arrays to hold ciphertexts and expected plaintexts
    reg [127:0] ciphertexts [0:9];
    reg [127:0] expected_plaintexts [0:9];

    // Instantiate the AES decryption top module
    decrypt_top uut (
        .clk(clk),
        .rst(rst),
        .ciphertext(ciphertext),
        .key(key),
        .plaintext(plaintext)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test sequence
    initial begin
        // Initialize inputs
        rst = 1;
        key = 128'h000102030405060708090a0b0c0d0e0f;

        // Initialize ciphertexts
        ciphertexts[0] = 128'h3071708ffd2412229b2677ba5f1c52d2; // Example ciphertext
        ciphertexts[1] = 128'h7727a9f92c7f254cf18e29b4572b0c83; // Example ciphertext
        ciphertexts[2] = 128'h69c4e0d86a7b0430d8cdb78070b4c55a; // Example ciphertext
        ciphertexts[3] = 128'h1b872378795f4ffd772855fc87ca964d; // Example ciphertext
        ciphertexts[4] = 128'h5ba2aeb13eb7b926be9dfcc27792042d; // Example ciphertext
        ciphertexts[5] = 128'h6be09ebc06a13783f436f5cb9c11a5b0; // Example ciphertext
        ciphertexts[6] = 128'hc6a13b37878f5b826f4f8162a1c8d879; // Example ciphertext
        ciphertexts[7] = 128'h3c441f32ce07822364d7a2990e50bb13; // Example ciphertext
        ciphertexts[8] = 128'h53dda1feb1843a1948c39341030cd52b; // Example ciphertext
        ciphertexts[9] = 128'h3c3f19a3f3b5e6287e1d79eec2a5d11e; // Example ciphertext

        // Initialize expected plaintexts (placeholders)
        expected_plaintexts[0] = 128'h0123456789abcdef0123456789abcdef; // Replace with actual expected result
        expected_plaintexts[1] = 128'hfedcba9876543210fedcba9876543210; // Replace with actual expected result
        expected_plaintexts[2] = 128'h00112233445566778899aabbccddeeff; // Replace with actual expected result
        expected_plaintexts[3] = 128'hffeeddccbbaa99887766554433221100; // Replace with actual expected result
        expected_plaintexts[4] = 128'h1234567890abcdef1234567890abcdef; // Replace with actual expected result
        expected_plaintexts[5] = 128'habcdef0123456789abcdef0123456789; // Replace with actual expected result
        expected_plaintexts[6] = 128'h00000000000000000000000000000000; // Replace with actual expected result
        expected_plaintexts[7] = 128'hffffffffffffffffffffffffffffffff; // Replace with actual expected result
        expected_plaintexts[8] = 128'hdeadbeefdeadbeefdeadbeefdeadbeef; // Replace with actual expected result
        expected_plaintexts[9] = 128'hcafebabecafebabecafebabecafebabe; // Replace with actual expected result

        // Apply reset
        #10 rst = 0;

        // Stream of 10 data inputs
        for (int i = 0; i < 10; i++) begin
            // Wait for one clock cycle
            @(posedge clk);
            // Apply the next ciphertext
            ciphertext = ciphertexts[i];
        end

        // Wait for the decryption to complete for the last input
        #100;

        // Wait until plaintext is no longer unknown
        wait (plaintext !== 128'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX);

        // Check the resulting plaintext
        for (int i = 0; i < 10; i++) begin
            if (plaintext === expected_plaintexts[i]) begin
                $display("Test %0d Passed: Plaintext matches expected value.", i);
            end else begin
                $display("Test %0d Failed: Plaintext does not match expected value.", i);
                $display("Expected: %h, Got: %h", expected_plaintexts[i], plaintext);
            end
        end
        #250;
        // Finish the simulation
        $finish;
    end

endmodule

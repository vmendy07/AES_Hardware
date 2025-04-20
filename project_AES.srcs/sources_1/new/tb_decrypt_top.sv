`timescale 1ns / 1ps

module tb_decrypt_top;

    // Testbench signals
    reg clk;
    reg rst;
    reg [127:0] ciphertext;
    reg [127:0] key;
    wire [127:0] plaintext;

    // Expected plaintext for comparison
    reg [127:0] expected_plaintext;

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
        ciphertext = 128'h69c4e0d86a7b0430d8cdb78070b4c55a; // Example ciphertext
        key = 128'h000102030405060708090a0b0c0d0e0f;
        expected_plaintext = 128'h00112233445566778899aabbccddeeff; // Expected plaintext

        // Apply reset
        #10 rst = 0;

        // Wait for the decryption to complete
        #100;

        // Check the resulting plaintext
        if (plaintext === expected_plaintext) begin
            $display("Test Passed: Plaintext matches expected value.");
        end else begin
            $display("Test Failed: Plaintext does not match expected value.");
            $display("Expected: %h, Got: %h", expected_plaintext, plaintext);
        end

        // Finish the simulation
        $finish;
    end

endmodule
`timescale 1ns / 1ps

module tb_encrypt_top;

    // Testbench signals
    reg clk;
    reg rst;
    reg [127:0] plaintext;
    reg [127:0] key;
    wire [127:0] ciphertext;

    // Expected ciphertext for comparison
    reg [127:0] expected_ciphertext;

    // Instantiate the AES top module
    encrypt_top uut (
        .clk(clk),
        .rst(rst),
        .plaintext(plaintext),
        .key(key),
        .ciphertext(ciphertext)
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
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key = 128'h000102030405060708090a0b0c0d0e0f;
        expected_ciphertext = 128'h69c4e0d86a7b0430d8cdb78070b4c55a; // Example expected result

        // Apply reset
        #10 rst = 0;

        // Wait for the encryption to complete
        #100;

        // Check the resulting ciphertext
        if (ciphertext === expected_ciphertext) begin
            $display("Test Passed: Ciphertext matches expected value.");
        end else begin
            $display("Test Failed: Ciphertext does not match expected value.");
            $display("Expected: %h, Got: %h", expected_ciphertext, ciphertext);
        end

        // Finish the simulation
        $finish;
    end

endmodule
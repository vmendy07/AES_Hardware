`timescale 1ns / 1ps

module tb_encrypt_top;

    // Testbench signals
    reg clk;
    reg rst;
    reg [127:0] plaintext;
    reg [127:0] key;
    wire [127:0] ciphertext;

    // Arrays to hold plaintexts and expected ciphertexts
    reg [127:0] plaintexts [0:9];
    reg [127:0] expected_ciphertexts [0:9];

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
        key = 128'h000102030405060708090a0b0c0d0e0f;

        // Initialize plaintexts
        plaintexts[0] = 128'h0123456789abcdef0123456789abcdef;
        plaintexts[1] = 128'hfedcba9876543210fedcba9876543210;
        plaintexts[2] = 128'h00112233445566778899aabbccddeeff;
        plaintexts[3] = 128'hffeeddccbbaa99887766554433221100;
        plaintexts[4] = 128'h1234567890abcdef1234567890abcdef;
        plaintexts[5] = 128'habcdef0123456789abcdef0123456789;
        plaintexts[6] = 128'h00000000000000000000000000000000;
        plaintexts[7] = 128'hffffffffffffffffffffffffffffffff;
        plaintexts[8] = 128'hdeadbeefdeadbeefdeadbeefdeadbeef;
        plaintexts[9] = 128'hcafebabecafebabecafebabecafebabe;

        // Initialize expected ciphertexts (placeholders)
        expected_ciphertexts[0] = 128'h3071708ffd2412229b2677ba5f1c52d2; // Replace with actual expected result
        expected_ciphertexts[1] = 128'h7727a9f92c7f254cf18e29b4572b0c83; // Replace with actual expected result
        expected_ciphertexts[2] = 128'h69c4e0d86a7b0430d8cdb78070b4c55a; // Replace with actual expected result
        expected_ciphertexts[3] = 128'h1b872378795f4ffd772855fc87ca964d; // Replace with actual expected result
        expected_ciphertexts[4] = 128'h5ba2aeb13eb7b926be9dfcc27792042d; // Replace with actual expected result
        expected_ciphertexts[5] = 128'h6be09ebc06a13783f436f5cb9c11a5b0; // Replace with actual expected result
        expected_ciphertexts[6] = 128'hc6a13b37878f5b826f4f8162a1c8d879; // Replace with actual expected result
        expected_ciphertexts[7] = 128'h3c441f32ce07822364d7a2990e50bb13; // Replace with actual expected result
        expected_ciphertexts[8] = 128'h53dda1feb1843a1948c39341030cd52b; // Replace with actual expected result
        expected_ciphertexts[9] = 128'h3c3f19a3f3b5e6287e1d79eec2a5d11e; // Replace with actual expected result

        // Apply reset
        #10 rst = 0;

        // Stream of 10 data inputs
        for (int i = 0; i < 10; i++) begin
            // Wait for one clock cycle
            @(posedge clk);
            // Apply the next plaintext
            plaintext = plaintexts[i];
        end

        // Wait for the encryption to complete for the last input
        #100;

        // Wait until ciphertext is no longer unknown
        wait (ciphertext !== 128'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX);

        // Check the resulting ciphertext
        for (int i = 0; i < 10; i++) begin
            if (ciphertext === expected_ciphertexts[i]) begin
                $display("Test %0d Passed: Ciphertext matches expected value.", i);
            end else begin
                $display("Test %0d Failed: Ciphertext does not match expected value.", i);
                $display("Expected: %h, Got: %h", expected_ciphertexts[i], ciphertext);
            end
        end
        #250;
        // Finish the simulation
        $finish;
    end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.03.2025 12:25:29
// Design Name: 
// Module Name: aes_decrypt_increment_tb
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


module aes_decrypt_round_test_tb;

  // Clock and Reset
  logic clk;
  logic rst;

  // Inputs
  logic i_start;
  logic [127:0] i_state;   // Ciphertext or intermediate state
  logic [127:0] seed_key;  // Original AES key

  // Outputs
  logic [127:0] o_state;   // Decryption output
  logic o_valid;           // Output valid signal

  // Internal signals for key expansion
  logic [127:0] round_keys [0:10];  // Store round keys for display

  // Instantiate the DUT (Device Under Test)
  aes_decrypt_round_test dut (
      .clk(clk),
      .rst(rst),
      .i_start(i_start),
      .i_state(i_state),
      .seed_key(seed_key),
      .o_state(o_state),
      .o_valid(o_valid)
  );

  // Clock Generation
  always #5 clk = ~clk;  // 10 ns clock period (100 MHz)

  // Test Vectors
  localparam [127:0] TEST_CIPHERTEXT = 128'h3925841d02dc09fbdc118597196a0b32; // Example ciphertext
  localparam [127:0] TEST_KEY = 128'h2b7e151628aed2a6abf7158809cf4f3c;     // Example AES-128 key
  localparam [127:0] EXPECTED_OUTPUT = 128'h3243f6a8885a308d313198a2e0370734; // Expected plaintext

  // Test Sequence
  initial begin
    // Initialise signals
    clk = 0;
    rst = 1;
    i_start = 0;
    i_state = 128'd0;
    seed_key = 128'd0;

    // Reset pulse
    #20;
    rst = 0;
    #20;

    // Provide input values
    seed_key = TEST_KEY;
    i_state = TEST_CIPHERTEXT;
    i_start = 1;
    
    // Display initial values
    $display("\n=== AES Decryption Test Start ===");
    $display("Initial Ciphertext : %h", i_state);
    $display("Seed Key           : %h\n", seed_key);

    #10;
    i_start = 0;  // Start pulse complete

    // Wait for key expansion to generate round keys
    $display("\n=== Key Expansion Process ===");
    for (int round = 0; round <= 10; round++) begin
      #10; // Wait for each key to be generated
      round_keys[round] = dut.round_keys[round]; // Ensure this matches your module
      $display("Round %0d Key: %h", round, round_keys[round]);
    end

    // Initial AddRoundKey
    #10;
    $display("\n=== Initial AddRoundKey (Before Any Rounds) ===");
    $display("State Before AddRoundKey : %h", i_state);
    $display("Round 10 Key Used        : %h", round_keys[10]);
    $display("State After AddRoundKey  : %h\n", dut.state_reg);

    // Display intermediate decryption steps
    $display("\n=== Decryption Rounds ===");
    for (int round = 10; round >= 1; round--) begin
      #10; // Wait for each round
      $display("=== Round %0d ===", round);
      $display("State Before AddRoundKey : %h", dut.state_reg);
      $display("State After InvShiftRows : %h", dut.inv_shift_out);
      $display("State After InvSubBytes  : %h", dut.inv_sub_out);
      if (round > 1) begin
        $display("State After InvMixColumns: %h", dut.mix_out);
      end
      $display("Round Key Used           : %h", round_keys[round - 1]);
      $display("State After AddRoundKey  : %h\n", dut.reg_final);
    end

    // Wait for decryption process to complete
    wait(o_valid);
    #10;

    // Display final decrypted plaintext
    $display("\n=== Decryption Complete ===");
    $display("Final Output (Plaintext) : %h", o_state);

    // Check if output matches expected plaintext
    if (o_state == EXPECTED_OUTPUT) begin
      $display("Test Passed! Output matches expected plaintext.");
    end else begin
      $display("Test Failed! Expected: %h, Got: %h", EXPECTED_OUTPUT, o_state);
    end

    // Finish Simulation
    #50;
    $finish;
  end

endmodule






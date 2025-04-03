`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 15:46:30
// Design Name: 
// Module Name: aes_decryption_top_tb
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


module aes_decrypt_tb;

  // Clock and Reset
  logic clk;
  logic rst;

  // Inputs
  logic i_start;
  logic [127:0] i_ciphertext;  // Matches i_state in your main module
  logic [127:0] i_key;         // Matches seed_key in your main module

  // Outputs
  logic [127:0] o_plaintext;   // Matches o_state in your main module
  logic o_valid;               // Output valid signal

  // Internal signals for key expansion
  logic [127:0] round_keys [0:10];  

  // Instantiate the DUT
  aes_decrypt_top dut (
      .clk(clk),
      .rst(rst),
      .i_start(i_start),
      .i_ciphertext(i_ciphertext),
      .i_key(i_key),
      .o_plaintext(o_plaintext),
      .o_valid(o_valid)
  );

  // Clock Generation (10 ns period, 100 MHz)
  always #5 clk = ~clk;

  // Test Vectors
  localparam [127:0] TEST_CIPHERTEXT = 128'h3925841d02dc09fbdc118597196a0b32;
  localparam [127:0] TEST_KEY = 128'h2b7e151628aed2a6abf7158809cf4f3c;
  localparam [127:0] EXPECTED_OUTPUT = 128'h3243f6a8885a308d313198a2e0370734;

  // Test Sequence
  initial begin
    // Initialise signals
    clk = 0;
    rst = 1;
    i_start = 0;
    i_ciphertext = 128'd0;
    i_key = 128'd0;

    // Reset pulse
    #20;
    rst = 0;
    #20;

    // Provide input values
    i_key = TEST_KEY;
    i_ciphertext = TEST_CIPHERTEXT;
    i_start = 1;

    $display("\n=== AES Decryption Test Start ===");
    $display("Ciphertext: %h", i_ciphertext);
    $display("Key       : %h\n", i_key);

    #10;
    i_start = 0;  // Start pulse complete

    // **Wait for Key Expansion to Complete**
    #10
    $display("\n=== Key Expansion Complete ===");

    for (int round = 0; round <= 10; round++) begin
      round_keys[round] = dut.round_keys[round];
      $display("Round %0d Key: %h", round, round_keys[round]);
    end

    // **Wait for First AddRoundKey Valid**
    #10
    $display("\n=== Initial AddRoundKey ===");
    $display("State Before AddRoundKey : %h", i_ciphertext);
    $display("Round 10 Key Used        : %h", round_keys[10]);
    $display("State After AddRoundKey  : %h\n", dut.state_reg);

    // **Iterate Through Decryption Rounds**
    $display("\n=== Decryption Rounds ===");
    for (int round = 10; round >= 0; round--) begin
      #10  // Wait for round completion
      $display("=== Round %0d ===", round);
      $display("Input To Round : %h", dut.state_reg);
      
      wait(dut.inv_shift_valid);
      $display("State After InvShiftRows : %h", dut.reg_shift);

      wait(dut.inv_sub_valid);
      $display("State After InvSubBytes  : %h", dut.reg_sub);

      wait(dut.add_valid);
      $display("Round Key Used           : %h", round_keys[round - 1]);
      $display("State After AddRoundKey  : %h", dut.reg_add_r);

      if (round > 0) begin
        wait(dut.inv_mix_valid);
        $display("State After InvMixColumns: %h\n", dut.reg_mix);
      end
    end      

/*    // **Final Round (No InvMixColumns)**
    #10
    $display("=== Final Round ===");
    $display("Input To Round : %h", dut.state_reg);
    
    wait(dut.inv_shift_valid);
    $display("State After InvShiftRows : %h", dut.reg_shift);

    wait(dut.inv_sub_valid);
    $display("State After InvSubBytes  : %h", dut.reg_sub);

    wait(dut.add_valid);
    $display("Round Key Used           : %h", round_keys[0]);
    $display("State After AddRoundKey  : %h\n", dut.state_reg);

    // **Wait for Final Output Valid**
    wait(o_valid);
    $display("\n=== Decryption Complete ===");
    $display("Final Output (Plaintext) : %h", o_plaintext);

    // Check if output matches expected plaintext
    if (o_plaintext == EXPECTED_OUTPUT) begin
      $display("Test Passed! Output matches expected plaintext.");
    end else begin
      $display("Test Failed! Expected: %h, Got: %h", EXPECTED_OUTPUT, o_plaintext);
    end*/

    // Finish Simulation
    #10;
    $finish;
  end

endmodule






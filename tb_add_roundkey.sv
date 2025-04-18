//////////////////////////////////////////////////////////////////////////////////
// Organisation: University of Sheffield
// Engineer: Vincent Mendy
// Date Created: 18.01.2025 17:41:16
// Design Title: AES AddRoundKey Module
// Module Name: add_roundkey
// Project: AES Implementation
// Target Devices: FPGA 
// Tool Version: Xilinx Vivado 2021.2
// Description: 
//   This module implements the AddRoundKey operation of the AES cipher.
//   It computes a bitwise XOR between a 128-bit data state and a 128-bit round key,
//   which is a critical step in every AES round.
// Dependencies: None (implements a combinational XOR operation)
// Revision History:
//   Rev 0.1: Initial implementation of the AddRoundKey module.
//////////////////////////////////////////////////////////////////////////////////
module tb_add_roundkey;  // Testbench module for verifying add_roundkey functionality

  // Testbench signals declaration:
  logic [127:0] tb_state;      // 128-bit signal representing the current AES state (input to the DUT)
  logic [127:0] tb_round_key;  // 128-bit signal representing the round key (input to the DUT)
  logic [127:0] tb_state_out;  // 128-bit signal for the output state from the DUT (result of XOR)

  // Instantiate the Unit Under Test (UUT): the add_roundkey module
  add_roundkey uut (
    .state(tb_state),          // Connects testbench state input to the module's state input
    .round_key(tb_round_key),  // Connects the round key input from testbench to the module
    .state_out(tb_state_out)   // Connects the output from the module to testbench signal
  );

  // Initial block: It applies stimuli (test vectors) and verifies the DUT behavior.
  initial begin
    $display("Starting add_roundkey testbench...");  // Print a message to indicate that testing has begun

    // Test Case 1: Uses a known test vector pair.
    // Inputs:
    //   State:     00112233 44556677 8899aabb ccddeeff
    //   Round Key: 00010203 04050607 08090a0b 0c0d0e0f
    // Expected Output:
    //   XOR of state and round key = 00 10 20 30 40 50 60 70 80 90 a0 b0 c0 d0 e0 f0
    tb_state = 128'h00112233445566778899aabbccddeeff;  // Assign test vector for state
    tb_round_key = 128'h000102030405060708090a0b0c0d0e0f;  // Assign test vector for round key
    #10;  // Wait 10 time units to allow the result to propagate through the combinational logic

    // Display and verify the results for Test Case 1:
    $display("Test Case 1:");
    $display("  State:     %h", tb_state);
    $display("  Round Key: %h", tb_round_key);
    $display("  Output:    %h", tb_state_out);

    // Check the simultaneously computed output against the expected result:
    if (tb_state_out === 128'h00102030405060708090a0b0c0d0e0f0)
      $display("  PASS: Test Case 1\n");  // Correct result: display PASS message
    else
      $display("  FAIL: Test Case 1\n");  // Incorrect result: display FAIL message
    
    // Test Case 2: Applies a different test vector.
    // Inputs:
    //   State:     ffffffffffffffffffffffffffffffff (all bits set to 1)
    //   Round Key: 0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f (repeating pattern of 0f)
    // Expected Output:
    //   Result of state XOR round key = f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
    tb_state = 128'hffffffffffffffffffffffffffffffff;  // Set state to all ones (hex FFFF…)
    tb_round_key = 128'h0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;  // Set round key with the pattern 0f
    #10;  // Wait for the result to settle

    // Display and verify the results for Test Case 2:
    $display("Test Case 2:");
    $display("  State:     %h", tb_state);
    $display("  Round Key: %h", tb_round_key);
    $display("  Output:    %h", tb_state_out);

    // Compare the output with the expected XOR result:
    if (tb_state_out === 128'hf0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0)
      $display("  PASS: Test Case 2\n");
    else
      $display("  FAIL: Test Case 2\n");

    $finish;  // Terminate the simulation
  end

endmodule
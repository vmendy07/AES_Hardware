//////////////////////////////////////////////////////////////////////////////////
// Organisation: University of Sheffield
// Engineer: Vincent Mendy
// Date Created: 18.01.2025 17:41:16
// Design Title: Testbench for Generic SubBytes Operation
// Module Name: tb_subbytes_generic
// Project: AES Implementation
// Target Devices: FPGA 
// Tool Version: Xilinx Vivado 2021.2
// Description: 
//   This testbench verifies the operation of the subbytes_generic module, which implements
//   the SubBytes transformation for AES. In forward mode (mode = 0), the module substitutes
//   each byte of a 128-bit state using the forward S-box. In inverse mode (mode = 1), it applies
//   the inverse S-box to each byte.
// Dependencies: subbytes_generic.sv (Module under test)
// Revision History:
//   Rev 0.1: Initial testbench set up with test cases covering both forward and inverse operations.
// Additional Notes:
//   The clock is generated with a 10 time unit period, and the asynchronous active-low reset is used
//   to initialize the module. Test vectors are applied and results are displayed for verification.
//////////////////////////////////////////////////////////////////////////////////

module tb_subbytes_generic;

  // Testbench signal declarations:
  // clk: Clock input used to drive synchronous operations.
  // rst_n: Active-low reset input; when low, it resets internal states.
  // mode: Selects between forward substitution (0) and inverse substitution (1).
  // state: 128-bit input state containing 16 bytes to be substituted.
  // state_out: 128-bit output state after applying the S-box substitution.
  logic         clk, rst_n, mode;
  logic [127:0] state;
  logic [127:0] state_out, expected_state;
  logic         o_valid;
  

  // Clock generation: Creates a clock with a period of 10 time units (5 time units high, 5 low).
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // Toggle the clock every 5 time units.
  end

  // Instantiate the subbytes_generic module (the Unit Under Test).
  subbytes_generic uut (
    .clk      (clk),        // Connect the clock.
    .rst_n    (rst_n),      // Connect the reset signal.
    .mode     (mode),       // Connect the mode selection (forward/inverse).
    .state    (state),      // Apply the input state.
    .state_out(state_out),  // Route the output after substitution.
    .o_valid  (o_valid)      // Connect the o_valid signal
  );

  // Test sequence: Apply various stimuli for both forward and inverse SubBytes operations.
  initial begin
    // Initialize with reset asserted (active-low) and set to forward substitution mode.
    rst_n = 0;
    state = 128'h0;
    mode  = 0;  // Mode 0 for forward SubBytes.
    #12;        // Wait 12 time units (ensuring reset propagation).
    rst_n = 1;  // Release reset, begin normal operation.

    // ---------------------------
    // Forward SubBytes Testing
    // ---------------------------
    // Test 1: When all input bytes are 0x00, each should map to 8'h63 (per the forward S-box).
    state = 128'h00000000000000000000000000000000;
    mode  = 0;  // Maintain forward mode.
    #10;        // Allow substitution to process.
    @(posedge o_valid);  // Wait for o_valid to be asserted
    $display("\nForward Mode - Test 1: All zeros => Expect 0x63 for each byte");
    $display("Input  = %h", state);
    $display("Output = %h", state_out);

    // Test 2: When all input bytes are 0xFF, each should map to 8'h16 (last entry of the forward S-box).
    state = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    mode  = 0;  // Ensure forward mode.
    #10;        // Wait for the substitution to settle.
    @(posedge o_valid);  // Wait for o_valid to be asserted
    $display("\nForward Mode - Test 2: All 0xFF => Expect 0x16 for each byte");
    $display("Input  = %h", state);
    $display("Output = %h", state_out);

    // ---------------------------
    // Inverse SubBytes Testing
    // ---------------------------
    // Switch to inverse mode to test the de-substitution.
    // mode = 1;

    // // Test 3: When each input byte is 0x63, the output should be 0x00 because inv_sbox[8'h63] = 8'h00.
    // state = 128'h63636363636363636363636363636363;
    // #10;        // Wait for the substitution.
    // @(posedge o_valid);  // Wait for o_valid to be asserted
    // $display("\nInverse Mode - Test 1: All 0x63 => Expect 0x00 for each byte");
    // $display("Input  = %h", state);
    // $display("Output = %h", state_out);

    // // Test 4: When each input byte is 0x16, the output should be 0xFF as inv_sbox[8'h16] = 8'hFF.
    // state = 128'h16161616161616161616161616161616;
    // #10;        // Allow time for processing.
    // @(posedge o_valid);  // Wait for o_valid to be asserted
    // $display("\nInverse Mode - Test 2: All 0x16 => Expect 0xFF for each byte");
    // $display("Input  = %h", state);
    // $display("Output = %h", state_out);
    
    
    // Test 3: When each input byte is 0x16, the output should be 0xFF as inv_sbox[8'h16] = 8'hFF.
    state = 128'h00102030405060708090a0b0c0d0e0f0;
    expected_state = 128'h63cab7040953d051cd60e0e7ba70e18c;
    #10;        // Allow time for processing.
    @(posedge o_valid);  // Wait for o_valid to be asserted
    $display("\nForward Mode - Test 3: All 0x16 => Expect 63cab7040953d051cd60e0e7ba70e18c for each byte");
    $display("Input  = %h", state);
    $display("Output = %h", state_out);
    if (state_out == expected_state)
        $display("Yahoo, all tests Passed!");
    else
        $display("Failed tests!");
    $finish;   // Terminate the simulation.
  end

endmodule 
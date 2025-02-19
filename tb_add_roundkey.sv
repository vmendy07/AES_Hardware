 module tb_add_roundkey;

  // Testbench signals
  logic [127:0] tb_state;
  logic [127:0] tb_round_key;
  logic [127:0] tb_state_out;

  // Instantiate the Unit Under Test (UUT)
  add_roundkey uut (
    .state(tb_state),
    .round_key(tb_round_key),
    .state_out(tb_state_out)
  );

  initial begin
    $display("Starting add_roundkey testbench...");

    // Test Case 1: Using a well-known test vector
    // State:     00112233 44556677 8899aabb ccddeeff
    // Round Key: 00010203 04050607 08090a0b 0c0d0e0f
    // Expected Output = State XOR Round Key = 00 10 20 30 40 50 60 70 80 90 a0 b0 c0 d0 e0 f0
    tb_state = 128'h00112233445566778899aabbccddeeff;
    tb_round_key = 128'h000102030405060708090a0b0c0d0e0f;
    #10;  // Wait for combinational results to propagate

    $display("Test Case 1:");
    $display("  State:     %h", tb_state);
    $display("  Round Key: %h", tb_round_key);
    $display("  Output:    %h", tb_state_out);

    if (tb_state_out === 128'h00102030405060708090a0b0c0d0e0f0)
      $display("  PASS: Test Case 1\n");
    else
      $display("  FAIL: Test Case 1\n");
    
    // Test Case 2: Using another vector
    // State:     ffffffffffffffffffffffffffffffff
    // Round Key: 0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f
    // Expected Output = State XOR Round Key = f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
    tb_state = 128'hffffffffffffffffffffffffffffffff;
    tb_round_key = 128'h0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
    #10;  // Wait again for the result

    $display("Test Case 2:");
    $display("  State:     %h", tb_state);
    $display("  Round Key: %h", tb_round_key);
    $display("  Output:    %h", tb_state_out);

    if (tb_state_out === 128'hf0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0)
      $display("  PASS: Test Case 2\n");
    else
      $display("  FAIL: Test Case 2\n");

    $finish;
  end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Organisation: University of Sheffield
// Engineer: EBranners
// 
// Create Date:    30.03.2025
// Design Title:   AES Inverse MixColumns Testbench
// Module Name:    tb_inv_mixcolumns
// Project Name:   AES Implementation
// Target Devices: FPGA
// Tool Version:   Xilinx Vivado 2021.2
// Description: 
//   Testbench to verify the AES Inverse MixColumns module. It checks output
//   against a golden model implementation of the inverse MixColumns operation.
//   Includes known-answer tests, zero vectors, and pseudo-random tests.
//
// Dependencies: 
//   - inv_mixcolumns.sv
//
// Revision History:
//   Rev 0.2 - Improved layout, documentation, and golden model testing
//   Rev 0.3 - Extended test coverage with edge cases and random tests
//
//////////////////////////////////////////////////////////////////////////////////

module tb_inv_mixcolumns;

  // DUT I/O
  reg          i_valid;
  reg [127:0]  i_block;
  wire         o_valid;
  wire [127:0] o_block;

  reg [127:0] rand_vector;

  //----------------------------------------------------------------------
  // GF(2^8) multiplication function
  //----------------------------------------------------------------------  
  function [7:0] gmul;
    input [7:0] a, b;
    reg [7:0] p;
    integer i;
    begin
      p = 0;
      for (i = 0; i < 8; i = i + 1) begin
        if (b[0]) p ^= a;
        b = b >> 1;
        a = (a << 1) ^ (a[7] ? 8'h1B : 8'h00);
      end
      gmul = p;
    end
  endfunction

  //----------------------------------------------------------------------
  // Golden model for Inverse MixColumns (column-wise AES matrix mult)
  //----------------------------------------------------------------------
  function [127:0] golden_inv_mixcolumns;
    input [127:0] state;
    reg [7:0] a0, a1, a2, a3;
    reg [7:0] r0, r1, r2, r3;
    reg [127:0] result;
    integer i;
    begin
      for (i = 0; i < 4; i = i + 1) begin
        a0 = state[127 - i*32 -: 8];
        a1 = state[119 - i*32 -: 8];
        a2 = state[111 - i*32 -: 8];
        a3 = state[103 - i*32 -: 8];

        r0 = gmul(a0, 8'h0E) ^ gmul(a1, 8'h0B) ^ gmul(a2, 8'h0D) ^ gmul(a3, 8'h09);
        r1 = gmul(a0, 8'h09) ^ gmul(a1, 8'h0E) ^ gmul(a2, 8'h0B) ^ gmul(a3, 8'h0D);
        r2 = gmul(a0, 8'h0D) ^ gmul(a1, 8'h09) ^ gmul(a2, 8'h0E) ^ gmul(a3, 8'h0B);
        r3 = gmul(a0, 8'h0B) ^ gmul(a1, 8'h0D) ^ gmul(a2, 8'h09) ^ gmul(a3, 8'h0E);

        result[127 - i*32 -: 8] = r0;
        result[119 - i*32 -: 8] = r1;
        result[111 - i*32 -: 8] = r2;
        result[103 - i*32 -: 8] = r3;
      end
      golden_inv_mixcolumns = result;
    end
  endfunction

  //----------------------------------------------------------------------
  // Task to perform a test and display result
  //----------------------------------------------------------------------
  task run_test;
    input [127:0] test_vector;
    input [127:0] expected;
    input integer test_num;
    begin
      $display("\n********** Test %0d **********", test_num);
      i_valid = 1;
      i_block = test_vector;
      #1;
      if (o_block === expected)
        $display("PASS: Expected = %h, Received = %h", expected, o_block);
      else begin
        $display("FAIL: Expected = %h, Received = %h", expected, o_block);
        $fatal;
      end
      i_valid = 0;
    end
  endtask

  //----------------------------------------------------------------------
  // Instantiate Unit Under Test
  //----------------------------------------------------------------------
  inv_mixcolumns uut (
    .i_valid(i_valid),
    .i_block(i_block),
    .o_valid(o_valid),
    .o_block(o_block)
  );

  //----------------------------------------------------------------------
  // Main test sequence
  //----------------------------------------------------------------------
  initial begin
    i_valid = 0;
    i_block = 0;
    rand_vector = 0;

    // Test 1: Known input/output (FIPS-style)
    run_test(128'h2ec27d03_c428e061_c5529e8f_9d9a53de,
             128'hd4e0b81e_bfb44127_5d521198_30aef1e5, 1);

    // Test 2: All-zero input
    run_test(128'h00000000000000000000000000000000,
             128'h00000000000000000000000000000000, 2);

    // Test 3: Random input (auto compute expected)
    rand_vector = { $urandom, $urandom, $urandom, $urandom };
    run_test(rand_vector, golden_inv_mixcolumns(rand_vector), 3);

    // Test 4: All 1s
    run_test(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
             golden_inv_mixcolumns(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF), 4);

    // Test 5: Known inverse (expected output precomputed)
    run_test(128'hba75f47a_84a48d32_e88d060e_1b407d5d,
             128'h632fafa2_eb93c720_9f92abcb_a0c0302b, 5);

    // Test 6: Another known inverse
    run_test(128'hbdf20b8b_6eb56110_7c7721b6_3d9e6e89,
             golden_inv_mixcolumns(128'hbdf20b8b_6eb56110_7c7721b6_3d9e6e89), 6);

    $display("\n✅ All tests completed successfully.");
    #20;
    $finish;
  end

endmodule

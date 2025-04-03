`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 15:30:36
// Design Name: 
// Module Name: inv_mix_column_tb
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


module tb_inv_mixcolumns;

  // Testbench signals
  reg          i_valid;
  reg [127:0]  i_block;
  wire         o_valid;
  wire [127:0] o_block;
  reg [127:0] rand_vector;

  //----------------------------------------------------------------------
  // GF(2^8) multiplication functions for inverse MixColumns
  //----------------------------------------------------------------------  
  function [7:0] gmul;
    input [7:0] a, b;
    reg [7:0] p;
    integer i;
    begin
      p = 8'h00;
      for (i = 0; i < 8; i = i + 1) begin
        if (b[0])
          p = p ^ a;
        b = b >> 1;
        a = (a << 1) ^ (a[7] ? 8'h1B : 8'h00);
      end
      gmul = p;
    end
  endfunction

  //----------------------------------------------------------------------
  // Golden Model Function for **Inverse** MixColumns Transformation.
  //----------------------------------------------------------------------
  function [127:0] golden_inv_mixcolumns;
    input [127:0] state;
    reg [7:0] a0, a1, a2, a3;
    reg [7:0] r0, r1, r2, r3;
    reg [127:0] result;
    begin
      // Column 0 (bits 127:96)
      a0 = state[127:120];
      a1 = state[119:112];
      a2 = state[111:104];
      a3 = state[103:96];
      r0 = gmul(a0, 8'h0E) ^ gmul(a1, 8'h0B) ^ gmul(a2, 8'h0D) ^ gmul(a3, 8'h09);
      r1 = gmul(a0, 8'h09) ^ gmul(a1, 8'h0E) ^ gmul(a2, 8'h0B) ^ gmul(a3, 8'h0D);
      r2 = gmul(a0, 8'h0D) ^ gmul(a1, 8'h09) ^ gmul(a2, 8'h0E) ^ gmul(a3, 8'h0B);
      r3 = gmul(a0, 8'h0B) ^ gmul(a1, 8'h0D) ^ gmul(a2, 8'h09) ^ gmul(a3, 8'h0E);
      result[127:120] = r0;
      result[119:112] = r1;
      result[111:104] = r2;
      result[103:96] = r3;

      // Column 1 (bits 95:64)
      a0 = state[95:88];
      a1 = state[87:80];
      a2 = state[79:72];
      a3 = state[71:64];
      r0 = gmul(a0, 8'h0E) ^ gmul(a1, 8'h0B) ^ gmul(a2, 8'h0D) ^ gmul(a3, 8'h09);
      r1 = gmul(a0, 8'h09) ^ gmul(a1, 8'h0E) ^ gmul(a2, 8'h0B) ^ gmul(a3, 8'h0D);
      r2 = gmul(a0, 8'h0D) ^ gmul(a1, 8'h09) ^ gmul(a2, 8'h0E) ^ gmul(a3, 8'h0B);
      r3 = gmul(a0, 8'h0B) ^ gmul(a1, 8'h0D) ^ gmul(a2, 8'h09) ^ gmul(a3, 8'h0E);
      result[95:88] = r0;
      result[87:80] = r1;
      result[79:72] = r2;
      result[71:64] = r3;

      // Column 2 (bits 63:32)
      a0 = state[63:56];
      a1 = state[55:48];
      a2 = state[47:40];
      a3 = state[39:32];
      r0 = gmul(a0, 8'h0E) ^ gmul(a1, 8'h0B) ^ gmul(a2, 8'h0D) ^ gmul(a3, 8'h09);
      r1 = gmul(a0, 8'h09) ^ gmul(a1, 8'h0E) ^ gmul(a2, 8'h0B) ^ gmul(a3, 8'h0D);
      r2 = gmul(a0, 8'h0D) ^ gmul(a1, 8'h09) ^ gmul(a2, 8'h0E) ^ gmul(a3, 8'h0B);
      r3 = gmul(a0, 8'h0B) ^ gmul(a1, 8'h0D) ^ gmul(a2, 8'h09) ^ gmul(a3, 8'h0E);
      result[63:56] = r0;
      result[55:48] = r1;
      result[47:40] = r2;
      result[39:32] = r3;

      // Column 3 (bits 31:0)
      a0 = state[31:24];
      a1 = state[23:16];
      a2 = state[15:8];
      a3 = state[7:0];
      r0 = gmul(a0, 8'h0E) ^ gmul(a1, 8'h0B) ^ gmul(a2, 8'h0D) ^ gmul(a3, 8'h09);
      r1 = gmul(a0, 8'h09) ^ gmul(a1, 8'h0E) ^ gmul(a2, 8'h0B) ^ gmul(a3, 8'h0D);
      r2 = gmul(a0, 8'h0D) ^ gmul(a1, 8'h09) ^ gmul(a2, 8'h0E) ^ gmul(a3, 8'h0B);
      r3 = gmul(a0, 8'h0B) ^ gmul(a1, 8'h0D) ^ gmul(a2, 8'h09) ^ gmul(a3, 8'h0E);
      result[31:24] = r0;
      result[23:16] = r1;
      result[15:8] = r2;
      result[7:0] = r3;

      golden_inv_mixcolumns = result;
    end
  endfunction

  //----------------------------------------------------------------------
  // Task to run an individual test.
  //----------------------------------------------------------------------
  task run_test;
    input [127:0] test_vector;
    input [127:0] expected;
    input integer test_num;
    begin
      $display("\n********** Test %0d **********", test_num);
      i_valid = 1;
      i_block = test_vector;
      #1; // Allow outputs to settle
      if (o_block === expected)
         $display("Test %0d PASS: Expected = %h, Received = %h", test_num, expected, o_block);
      else begin
         $display("Test %0d FAILED: Expected = %h, Received = %h", test_num, expected, o_block);
         $fatal;
      end
      i_valid = 0;
    end
  endtask

  // Instantiate the Inverse MixColumns Module Under Test (UUT)
  inv_mixcolumns uut (
    .i_valid(i_valid),
    .i_block(i_block),
    .o_valid(o_valid),
    .o_block(o_block)
  );

  //----------------------------------------------------------------------
  // Test Sequence: Apply multiple test vectors.
  //----------------------------------------------------------------------
  initial begin
  
      // Test 1: Known test vector (FIPS-197 example)
      // Input State (arranged in column-major order):
      //   Column 0: { 2e, c2, 7d, 03 }
      //   Column 1: { c4, 28, e0, 61 }
      //   Column 2: { c5, 52, 9e, 8f }
      //   Column 3: { 9d, 9a, 53, de }
      // Expected Output after Inv_MixColumns (as computed by our transformation):
      //   Column 0: { d4, e0, b8, 1e }
      //   Column 1: { bf, b4, 41, 27 }
      //   Column 2: { 5d, 52, 11, 98 }
      //   Column 3: { 30, ae, f1, e5 }
  
      run_test(128'h2ec27d03_c428e061_c5529e8f_9d9a53de,
               128'hd4e0b81e_bfb44127_5d521198_30aef1e5, 1);

      run_test(128'h00000000000000000000000000000000,
               128'h00000000000000000000000000000000, 2);

      rand_vector = { $urandom, $urandom, $urandom, $urandom };
      run_test(rand_vector, golden_inv_mixcolumns(rand_vector), 3);
      
      run_test(128'hba75f47a_84a48d32_e88d060e_1b407d5d,
               128'h632fafa2_eb93c720_9f92abcb_a0c0302b, 4); // Another test of known values
      
      run_test(128'hbdf20b8b_6eb56110_7c7721b6_3d9e6e89,
               128'h632fafa2_eb93c720_9f92abcb_a0c0302b, 4); // Another test of known values

      $display("\nAll tests completed successfully.");
      #20;
      $finish;
  end

endmodule

